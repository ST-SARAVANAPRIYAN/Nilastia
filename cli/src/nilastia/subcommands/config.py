from __future__ import annotations

import sys
from argparse import Namespace

try:
    from nilastia_needle.cli import run_query
    NEEDLE_AVAILABLE = True
except ImportError:
    NEEDLE_AVAILABLE = False


class Command:
    """Subcommand handler for 'nilastia config'."""

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if not NEEDLE_AVAILABLE:
            print(
                "Error: nilastia-needle plugin is not installed.\n\n"
                "Install it via:\n"
                "  pip install -e /home/saravana/projects/nilastia-needle --user --break-system-packages",
                file=sys.stderr
            )
            sys.exit(1)

        query_parts = getattr(self.args, "query", [])
        if query_parts and query_parts[0].lower() == "ask":
            query_parts = query_parts[1:]

        if not query_parts:
            print("Usage: nilastia config ask <request>\nExample: nilastia config ask 'make terminal 80% opaque'")
            return

        query_str = " ".join(query_parts).strip()
        dry_run = getattr(self.args, "dry_run", False)
        explain = getattr(self.args, "explain", False)
        confidence = getattr(self.args, "confidence", 0.80)
        model = getattr(self.args, "model", None)
        no_fallback = getattr(self.args, "no_fallback", False)

        code = run_query(
            query_str=query_str,
            dry_run=dry_run,
            explain=explain,
            confidence_threshold=confidence,
            model_path=model,
            enable_fallback=not no_fallback,
        )
        if code != 0:
            sys.exit(code)
