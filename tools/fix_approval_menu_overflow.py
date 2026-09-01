#!/usr/bin/env python3
"""Safe layout fixes for approval_screen menu overflow."""

from pathlib import Path
import re

PATH = Path(__file__).resolve().parents[1] / "lib/FE/approval_screen/approval_screen.dart"

COL_START = """                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          badges.Badge("""

COL_START_EXPANDED = """                                      Expanded(
                                        child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          badges.Badge("""

BETWEEN = """                                          )
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          badges.Badge("""

BETWEEN_EXPANDED = """                                          )
                                        ],
                                      ),
                                      ),
                                      Expanded(
                                        child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          badges.Badge("""

ROW_END = """                                          )
                                        ],
                                      ),
                                    ],"""

ROW_END_EXPANDED = """                                          )
                                        ],
                                      ),
                                      ),
                                    ],"""

HELPERS = """
  double _menuIconWidth(Size size, {int itemsPerRow = 4}) {
    const cardMargin = 0.08;
    const rowPadding = 48.0;
    final contentWidth = size.width * (1 - cardMargin * 2) - rowPadding;
    return contentWidth / itemsPerRow;
  }

  double _menuIconHeight(Size size) => _menuIconWidth(size) * 0.52;

"""


def main() -> None:
    text = PATH.read_text(encoding="utf-8")

    if "_menuIconWidth" not in text:
        text = text.replace(
            "  @override\n  Widget build(BuildContext context) {",
            HELPERS + "  @override\n  Widget build(BuildContext context) {",
        )

    text = text.replace(
        "                  Positioned(\n                    child: Column(",
        "                  Positioned(\n                    left: 0,\n                    right: 0,\n                    top: 0,\n                    child: Column(",
    )

    text = re.sub(
        r"\s*constraints: const BoxConstraints\(\s*maxHeight: double\.infinity,\s*\), //atur panjang kotak putih\n",
        "\n",
        text,
    )

    text = text.replace("height: size.height * 0.05,", "height: _menuIconHeight(size),")
    text = text.replace("width: size.width * 0.15,", "width: _menuIconWidth(size),")

    if COL_START_EXPANDED not in text:
        text = text.replace(BETWEEN, BETWEEN_EXPANDED)
        text = text.replace(ROW_END, ROW_END_EXPANDED)
        text = text.replace(COL_START, COL_START_EXPANDED)

    PATH.write_text(text, encoding="utf-8")
    print(f"Patched {PATH}")


if __name__ == "__main__":
    main()
