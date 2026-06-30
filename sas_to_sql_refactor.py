"""
SAS to SQL Stored Procedure Refactoring Tool
============================================================
Converts SAS jobs to Redshift-compatible stored procedures.

Refactoring pattern derived from:
  SAS  : SAS_JOBS/BAJA_CUPO_AUTOM.sas
  SQL  : schm_artifacts.sp_clts_baja_cupo  (all_sps_artifacts.sql, line 19297)

Usage:
  python sas_to_sql_refactor.py --sas SAS_JOBS/BAJA_CUPO_AUTOM.sas
  python sas_to_sql_refactor.py --sas SAS_JOBS/BAJA_CUPO_AUTOM.sas --out sql_files/sp_baja_cupo.sql
  python sas_to_sql_refactor.py --all         # convert every .sas in SAS_JOBS/
"""

import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# SAS library → Redshift schema
LIBRARY_MAP: dict[str, str] = {
    "PUBLICIN":  "schm_data_analytics",
    "RESULT":    "schm_data_analytics",
    "NLAGOSG":   "br_dm_prod_analytics_ripley_puntos_db",
    "WORK":      "schm_workspace",
    "SBARRERA":  "schm_artifacts",
}

# Procedure name prefix pattern: sp_<domain>_<base_name>
PROC_SCHEMA = "schm_artifacts"

# Default parameters injected into every generated procedure
DEFAULT_PARAMS = [
    ("v_period",         "int4"),
    ("v_nombre_campaing","varchar"),
    ("v_user",           "varchar"),
    ("v_fecha",          "varchar"),
    ("v_query",          "varchar"),
]


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class ConversionResult:
    sas_file: Path
    sql_file: Path
    proc_name: str
    warnings: list[str] = field(default_factory=list)
    skipped_blocks: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Core converter
# ---------------------------------------------------------------------------

class SAStoSQLConverter:
    """
    Rule-based converter that transforms SAS PROC SQL logic into a
    Redshift PL/pgSQL stored procedure.

    Strategy
    --------
    1. Strip SAS-only constructs (macros, DATA steps, PROC IMPORT/EXPORT, email).
    2. Extract SQL blocks from PROC SQL … QUIT.
    3. Apply syntax translations (null checks, functions, unions, schemas).
    4. Detect workspace (temp) tables to emit DROP TABLE IF EXISTS guards.
    5. Wrap everything in CREATE OR REPLACE PROCEDURE.
    6. Append a matching CALL template.
    """

    # ------------------------------------------------------------------
    # Regex catalogue
    # ------------------------------------------------------------------

    # SAS macro variable declarations: %let var = value;
    _RE_LET = re.compile(r"%let\s+(\w+)\s*=\s*([^;]+);", re.IGNORECASE)

    # %include / %macro invocations → drop entirely
    _RE_INCLUDE    = re.compile(r"%include[^;]+;", re.IGNORECASE | re.DOTALL)
    _RE_MACRO_CALL = re.compile(r"%[\w]+\([^)]*\)\s*;?", re.IGNORECASE)
    _RE_OPTIONS    = re.compile(r"options\s+[^;]+;", re.IGNORECASE)
    _RE_PUT        = re.compile(r"%put[^;]*;", re.IGNORECASE)
    _RE_TITLE      = re.compile(r"title[^;]*;", re.IGNORECASE)
    _RE_ODS        = re.compile(r"ODS\s+\w+[^;]*;", re.IGNORECASE | re.DOTALL)
    _RE_PROC_PRINT = re.compile(r"proc\s+print[^;]+;", re.IGNORECASE | re.DOTALL)

    # DATA _null_ / DATA steps (we only keep what we lift out earlier)
    _RE_DATA_STEP  = re.compile(
        r"DATA\s+_null_\s*;.*?run\s*;", re.IGNORECASE | re.DOTALL
    )
    _RE_DATA_STEP2 = re.compile(
        r"DATA\s+\w+\s*;.*?run\s*;", re.IGNORECASE | re.DOTALL
    )

    # PROC IMPORT / PROC EXPORT
    _RE_PROC_IMPORT  = re.compile(r"proc\s+import\b.*?run\s*;", re.IGNORECASE | re.DOTALL)
    _RE_PROC_EXPORT  = re.compile(r"proc\s+export\b.*?run\s*;", re.IGNORECASE | re.DOTALL)

    # Filename email blocks
    _RE_FILENAME_EMAIL = re.compile(
        r"Filename\s+\w+\s+EMAIL.*?RUN\s*;", re.IGNORECASE | re.DOTALL
    )

    # PROC SQL blocks – capture the inner SQL
    _RE_PROC_SQL = re.compile(
        r"PROC\s+SQL(?:\s+\w+)*\s*;(.*?)(?:QUIT|QUIT\s*;)", re.IGNORECASE | re.DOTALL
    )

    # Trailing semicolons inside captured SQL (SAS uses ";" but Redshift needs it too – keep)

    # SAS null semantics
    _RE_IS_MISSING     = re.compile(r"\bIS\s+MISSING\b",     re.IGNORECASE)
    _RE_IS_NOT_MISSING = re.compile(r"\bIS\s+NOT\s+MISSING\b", re.IGNORECASE)
    _RE_EQ_MISSING     = re.compile(r"=\s*MISSING\b",        re.IGNORECASE)  # val=MISSING

    # SAS OUTER UNION CORR → UNION ALL
    _RE_OUTER_UNION = re.compile(r"\bouter\s+union\s+corr\b", re.IGNORECASE)

    # SAS CATX(sep, c1, c2 ...) → c1 || sep || c2 ...
    _RE_CATX = re.compile(r"\bcatx\s*\(\s*'([^']+)'\s*,([^)]+)\)", re.IGNORECASE)

    # SAS CAT(…) → concat via ||
    _RE_CAT = re.compile(r"\bcat\s*\(([^)]+)\)", re.IGNORECASE)

    # SAS date functions
    _RE_TODAY    = re.compile(r"\btoday\s*\(\s*\)", re.IGNORECASE)
    _RE_DATETIME = re.compile(r"\bdatetime\s*\(\s*\)", re.IGNORECASE)

    # SAS library.table → schema.table
    _RE_LIBREF = re.compile(
        r"\b(" + "|".join(re.escape(k) for k in LIBRARY_MAP) + r")\.",
        re.IGNORECASE,
    )

    # Detect workspace (temp) table creation
    _RE_CREATE_TABLE = re.compile(
        r"CREATE\s+TABLE\s+([\w.]+)\s+AS", re.IGNORECASE
    )
    _RE_CREATE_TABLE_DDL = re.compile(
        r"CREATE\s+TABLE\s+([\w.]+)\s*\(", re.IGNORECASE
    )

    # SAS comment blocks at top (/* … */)
    _RE_HEADER_COMMENT = re.compile(r"^/\*.*?\*/", re.DOTALL)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def convert(self, sas_path: Path, out_path: Optional[Path] = None) -> ConversionResult:
        sas_text = sas_path.read_text(encoding="utf-8", errors="replace")

        proc_name = self._derive_proc_name(sas_path.stem)
        if out_path is None:
            out_path = sas_path.parent.parent / "sql_files" / f"sp_{sas_path.stem.lower()}.sql"

        warnings: list[str] = []
        skipped: list[str] = []

        # 1. Extract header comment (version history) for documentation
        header_doc = self._extract_header(sas_text)

        # 2. Extract %let macro variables (informational – surface as comments)
        macro_vars = self._extract_macro_vars(sas_text)

        # 3. Extract and translate PROC SQL blocks
        sql_blocks, extraction_warnings = self._extract_sql_blocks(sas_text)
        warnings.extend(extraction_warnings)

        # 4. Detect SAS-only constructs we cannot auto-convert
        skipped.extend(self._detect_unsupported(sas_text))

        # 5. Translate each SQL block
        translated_blocks: list[str] = []
        workspace_tables: list[str] = []
        for block in sql_blocks:
            translated, tbls = self._translate_block(block, warnings)
            translated_blocks.append(translated)
            workspace_tables.extend(tbls)

        workspace_tables = list(dict.fromkeys(workspace_tables))  # deduplicate, preserve order

        # 6. Render output
        sql_output = self._render_procedure(
            proc_name=proc_name,
            header_doc=header_doc,
            macro_vars=macro_vars,
            sql_blocks=translated_blocks,
            workspace_tables=workspace_tables,
            sas_file=sas_path.name,
        )

        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(sql_output, encoding="utf-8")

        return ConversionResult(
            sas_file=sas_path,
            sql_file=out_path,
            proc_name=f"{PROC_SCHEMA}.{proc_name}",
            warnings=warnings,
            skipped_blocks=skipped,
        )

    # ------------------------------------------------------------------
    # Extraction helpers
    # ------------------------------------------------------------------

    def _derive_proc_name(self, stem: str) -> str:
        """Convert file stem like BAJA_CUPO_AUTOM to sp_clts_baja_cupo."""
        # Remove common suffixes
        for suffix in ("_AUTOM", "_AUTO", "_CIERRE", "_DIARIO", "_AUT"):
            stem = re.sub(suffix + r"$", "", stem, flags=re.IGNORECASE)
        return f"sp_{stem.lower()}"

    def _extract_header(self, text: str) -> str:
        m = self._RE_HEADER_COMMENT.match(text.lstrip())
        return m.group(0) if m else ""

    def _extract_macro_vars(self, text: str) -> dict[str, str]:
        return {m[1].strip(): m[2].strip() for m in self._RE_LET.finditer(text)}

    def _extract_sql_blocks(self, text: str) -> tuple[list[str], list[str]]:
        warnings: list[str] = []
        blocks: list[str] = []
        for m in self._RE_PROC_SQL.finditer(text):
            inner = m.group(1).strip()
            if inner:
                blocks.append(inner)
        if not blocks:
            warnings.append(
                "No PROC SQL … QUIT blocks found. "
                "The file may use DATA steps or dynamic SQL that requires manual conversion."
            )
        return blocks, warnings

    def _detect_unsupported(self, text: str) -> list[str]:
        skipped: list[str] = []
        if self._RE_PROC_IMPORT.search(text):
            skipped.append("PROC IMPORT – replace with a source table reference or unload job")
        if self._RE_PROC_EXPORT.search(text):
            skipped.append("PROC EXPORT – replace with UNLOAD … TO 's3://…'")
        if self._RE_FILENAME_EMAIL.search(text):
            skipped.append("FILENAME EMAIL – replace with orchestration-layer email (e.g. BigdataSesClient)")
        if re.search(r"%INCLUDE", text, re.IGNORECASE):
            skipped.append("%INCLUDE macro – dependency on external SAS file; resolve manually")
        if re.search(r"Call\s+execute", text, re.IGNORECASE):
            skipped.append(
                "DATA _null_ / Call execute – dynamic SQL; review generated SQL for accuracy"
            )
        if re.search(r"sashelp\.vmember", text, re.IGNORECASE):
            skipped.append(
                "sashelp.vmember (dynamic table name lookup) – "
                "replace with a direct table reference or information_schema query"
            )
        return skipped

    # ------------------------------------------------------------------
    # Translation helpers
    # ------------------------------------------------------------------

    def _translate_block(self, block: str, warnings: list[str]) -> tuple[str, list[str]]:
        """Apply all SAS → SQL translation rules to a SQL block."""
        workspace_tables: list[str] = []

        # Collect workspace table names before translation
        for pattern in (self._RE_CREATE_TABLE, self._RE_CREATE_TABLE_DDL):
            for m in pattern.finditer(block):
                tbl = m.group(1).strip()
                # After schema mapping this will become schm_workspace.*
                normalized = self._map_schema(tbl)
                if normalized.startswith("schm_workspace."):
                    workspace_tables.append(normalized)

        block = self._apply_translations(block, warnings)

        # Collect workspace tables again after schema mapping
        for pattern in (self._RE_CREATE_TABLE, self._RE_CREATE_TABLE_DDL):
            for m in pattern.finditer(block):
                tbl = m.group(1).strip()
                if tbl.startswith("schm_workspace."):
                    workspace_tables.append(tbl)

        workspace_tables = list(dict.fromkeys(workspace_tables))
        return block, workspace_tables

    def _apply_translations(self, sql: str, warnings: list[str]) -> str:
        # 1. Schema / library mapping
        sql = self._RE_LIBREF.sub(self._replace_libref, sql)

        # 2. SAS null semantics
        sql = self._RE_IS_NOT_MISSING.sub("IS NOT NULL", sql)
        sql = self._RE_IS_MISSING.sub("IS NULL", sql)
        sql = self._RE_EQ_MISSING.sub("IS NULL", sql)

        # 3. SAS OUTER UNION CORR → UNION ALL
        sql = self._RE_OUTER_UNION.sub("UNION ALL", sql)

        # 4. catx(sep, c1, c2, ...) → c1 || 'sep' || c2 || ...
        sql = self._RE_CATX.sub(self._replace_catx, sql)

        # 5. cat(c1, c2) → c1 || c2
        sql = self._RE_CAT.sub(self._replace_cat, sql)

        # 6. SAS date functions → Redshift equivalents
        sql = self._RE_TODAY.sub("current_date", sql)
        sql = self._RE_DATETIME.sub("current_timestamp", sql)

        # 7. Remove NOPRINT, OUTOBS=n qualifiers from PROC SQL (already stripped but safety)
        sql = re.sub(r"\bNOPRINT\b", "", sql, flags=re.IGNORECASE)
        sql = re.sub(r"\boutobs\s*=\s*\d+", "", sql, flags=re.IGNORECASE)

        # 8. SAS INTO :var → comment out (macro variable assignment; keep as annotation)
        sql = re.sub(
            r"into\s+:\w+",
            "-- INTO :macro_var (removed – move to caller)",
            sql,
            flags=re.IGNORECASE,
        )

        # 9. SELECT * INTO :var FROM … → mark for manual review
        sql = re.sub(
            r"select\s+.*?\s+into\s+--.*?from",
            "-- [MANUAL] SELECT … INTO macro removed – extract as subquery\n-- FROM",
            sql,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # 10. SAS WORK. table references not already mapped
        sql = re.sub(r"\bwork\.", "schm_workspace.", sql, flags=re.IGNORECASE)

        # 11. Normalize semicolons: ensure each statement ends with ";"
        #     (SAS allows omitting the last one inside PROC SQL)
        sql = sql.strip()
        if sql and not sql.endswith(";"):
            sql += ";"

        return sql

    # ------------------------------------------------------------------
    # Regex replacement callbacks
    # ------------------------------------------------------------------

    def _replace_libref(self, m: re.Match) -> str:
        lib = m.group(1).upper()
        schema = LIBRARY_MAP.get(lib, lib.lower())
        return f"{schema}."

    @staticmethod
    def _replace_catx(m: re.Match) -> str:
        sep = m.group(1)          # separator string
        args = [a.strip() for a in m.group(2).split(",")]
        return f" || '{sep}' || ".join(args)

    @staticmethod
    def _replace_cat(m: re.Match) -> str:
        args = [a.strip() for a in m.group(1).split(",")]
        return " || ".join(args)

    @staticmethod
    def _map_schema(tbl: str) -> str:
        """Best-effort: if table has no schema prefix, assign schm_workspace."""
        if "." not in tbl:
            return f"schm_workspace.{tbl}"
        lib, name = tbl.split(".", 1)
        return f"{LIBRARY_MAP.get(lib.upper(), lib.lower())}.{name}"

    # ------------------------------------------------------------------
    # Rendering
    # ------------------------------------------------------------------

    def _render_procedure(
        self,
        proc_name: str,
        header_doc: str,
        macro_vars: dict[str, str],
        sql_blocks: list[str],
        workspace_tables: list[str],
        sas_file: str,
    ) -> str:

        params_str = ",\n    ".join(f"{n} {t}" for n, t in DEFAULT_PARAMS)

        drop_tables = "\n\t".join(
            f"DROP TABLE IF EXISTS {t};" for t in workspace_tables
        ) if workspace_tables else "-- no schm_workspace tables detected"

        blocks_joined = "\n\n\t".join(sql_blocks) if sql_blocks else (
            "-- TODO: no PROC SQL blocks found – review SAS file for DATA step logic"
        )

        macro_comment = ""
        if macro_vars:
            lines = "\n".join(
                f"    -- %let {k} = {v}" for k, v in macro_vars.items()
            )
            macro_comment = f"\n    -- SAS macro variables (move to caller / hardcode):\n{lines}\n"

        header_comment = ""
        if header_doc:
            # Clean up SAS encoding artifacts
            cleaned = re.sub(r"[^\x20-\x7e\n\t]", "?", header_doc)
            header_comment = f"/*\n  Ported from: {sas_file}\n\n{cleaned}\n*/\n\n"

        unload_template = (
            "\t-- UNLOAD example (replace v_query with your SELECT):\n"
            "\t-- EXECUTE\n"
            "\t-- 'UNLOAD(' || quote_literal(v_query) ||\n"
            "\t-- ') to ''s3://br-dm-prod-us-east-1-837538682169-raw/bigdata/campaign/'\n"
            "\t-- || v_nombre_campaing || '/' || v_nombre_campaing || '_' || v_fecha\n"
            "\t-- || '_0-' || v_user\n"
            "\t-- || ''' iam_role ''arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT''\n"
            "\t-- format csv parallel off HEADER ALLOWOVERWRITE extension ''csv'' DELIMITER '','';';"
        )

        base_name = proc_name[3:] if proc_name.startswith("sp_") else proc_name
        call_template = (
            f"-- CALL {PROC_SCHEMA}.{proc_name}(\n"
            f"--     schm_artifacts.f_period(trunc(DATEADD(MM,-1,current_date))),\n"
            f"--     '{proc_name.upper()}',\n"
            f"--     'SJARAM',\n"
            f"--     schm_artifacts.f_period(current_date)::VARCHAR,\n"
            f"--     'select * from schm_workspace.{base_name}_output'\n"
            f"-- );\n"
        )

        return f"""{header_comment}CREATE OR REPLACE PROCEDURE {PROC_SCHEMA}.{proc_name}(
    {params_str}
)
LANGUAGE plpgsql
AS $$
BEGIN
{macro_comment}
\t-- ================================================================
\t-- CLEANUP: drop workspace tables from previous run
\t-- ================================================================
\t{drop_tables}

\t-- ================================================================
\t-- MAIN LOGIC (translated from {sas_file})
\t-- ================================================================
\t{blocks_joined}

{unload_template}

\tRETURN;

\t-- Post-return cleanup
\t{drop_tables}

END;
$$;

-- ================================================================
-- CALL TEMPLATE
-- ================================================================
{call_template}
"""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Convert SAS jobs to Redshift stored procedures",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--sas",  metavar="FILE",  help="Single .sas file to convert")
    group.add_argument("--all",  action="store_true", help="Convert all .sas files in SAS_JOBS/")
    p.add_argument("--out",  metavar="FILE",  help="Output .sql file (single-file mode only)")
    p.add_argument("--sas-dir",  default="SAS_JOBS",  metavar="DIR",
                   help="Directory containing SAS files (default: SAS_JOBS)")
    p.add_argument("--sql-dir",  default="sql_files",  metavar="DIR",
                   help="Output directory for SQL files (default: sql_files)")
    return p.parse_args()


def _print_result(r: ConversionResult) -> None:
    print(f"\n{'='*60}")
    print(f"  SAS  : {r.sas_file.name}")
    print(f"  SQL  : {r.sql_file}")
    print(f"  PROC : {r.proc_name}")
    if r.warnings:
        print("  WARNINGS:")
        for w in r.warnings:
            print(f"    ⚠  {w}")
    if r.skipped_blocks:
        print("  MANUAL REVIEW REQUIRED:")
        for s in r.skipped_blocks:
            print(f"    ✗  {s}")
    if not r.warnings and not r.skipped_blocks:
        print("  ✓  Converted without warnings")
    print(f"{'='*60}")


def main() -> None:
    args = _parse_args()
    converter = SAStoSQLConverter()
    base = Path(".")

    if args.sas:
        sas_path = Path(args.sas)
        out_path  = Path(args.out) if args.out else None
        result = converter.convert(sas_path, out_path)
        _print_result(result)

    else:  # --all
        sas_dir = base / args.sas_dir
        sql_dir = base / args.sql_dir
        sas_files = sorted(sas_dir.glob("*.sas"))
        if not sas_files:
            print(f"No .sas files found in {sas_dir}")
            sys.exit(1)

        print(f"Converting {len(sas_files)} SAS files from {sas_dir} → {sql_dir}")
        ok = failed = 0
        for sas_file in sas_files:
            out = sql_dir / f"sp_{sas_file.stem.lower()}.sql"
            try:
                result = converter.convert(sas_file, out)
                _print_result(result)
                ok += 1
            except Exception as exc:
                print(f"  ERROR converting {sas_file.name}: {exc}")
                failed += 1

        print(f"\nDone: {ok} converted, {failed} failed out of {len(sas_files)} total.")


if __name__ == "__main__":
    main()
