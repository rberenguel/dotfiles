#
# To be used in a .awk file included with -i or -f
#
# Usage:
#   awk -i color.awk '{ print colorize("Hello World", "bold_red") }'
#

function colorize(message, color_name, _code) {
    _code = COLORS[color_name]
    if (_code == "") {
        return message
    }
    return "\033[" _code "m" message "\033[0m"
}

BEGIN {
    # Text Styles
    COLORS["reset"]     = "0"
    COLORS["bold"]      = "1"
    COLORS["dim"]       = "2"
    COLORS["underline"] = "4"
    COLORS["blink"]     = "5"
    COLORS["reverse"]   = "7"

    # 8 Normal Foreground Colors
    COLORS["black"]   = "30"; COLORS["red"]     = "31"
    COLORS["green"]   = "32"; COLORS["yellow"]  = "33"
    COLORS["blue"]    = "34"; COLORS["magenta"] = "35"
    COLORS["cyan"]    = "36"; COLORS["white"]   = "37"

    # 8 Bright Foreground Colors
    COLORS["light_black"]   = "90"; COLORS["light_red"]     = "91"
    COLORS["light_green"]   = "92"; COLORS["light_yellow"]  = "93"
    COLORS["light_blue"]    = "94"; COLORS["light_magenta"] = "95"
    COLORS["light_cyan"]    = "96"; COLORS["light_white"]   = "97"

    # 8 Normal Background Colors
    COLORS["bg_black"]   = "40"; COLORS["bg_red"]     = "41"
    COLORS["bg_green"]   = "42"; COLORS["bg_yellow"]  = "43"
    COLORS["bg_blue"]    = "44"; COLORS["bg_magenta"] = "45"
    COLORS["bg_cyan"]    = "46"; COLORS["bg_white"]   = "47"

    # 8 Bright Background Colors
    COLORS["bg_light_black"]   = "100"; COLORS["bg_light_red"]     = "101"
    COLORS["bg_light_green"]   = "102"; COLORS["bg_light_yellow"]  = "103"
    COLORS["bg_light_blue"]    = "104"; COLORS["bg_light_magenta"] = "105"
    COLORS["bg_light_cyan"]    = "106"; COLORS["bg_light_white"]   = "107"

    # Style combinations (examples)
    COLORS["bold_red"] = "1;31"; COLORS["bold_green"] = "1;32"
    COLORS["bold_blue"] = "1;34";
    COLORS["highlight"] = "48;5;226;38;5;16" # Yellow background, black text
    #
# Add these to your BEGIN block
#

# -- Solarized Dark Palette --

# Foreground Accents (38;5;... is for foreground)
COLORS["solar_yellow"]  = "38;5;136";  COLORS["solar_orange"] = "38;5;166"
COLORS["solar_red"]     = "38;5;160";  COLORS["solar_magenta"]= "38;5;161"
COLORS["solar_violet"]  = "38;5;61";   COLORS["solar_blue"]   = "38;5;33"
COLORS["solar_cyan"]    = "38;5;37";   COLORS["solar_green"]  = "38;5;106"

# Foreground Content
COLORS["solar_fg"]        = "38;5;244"; # base0
COLORS["solar_fg_light"]  = "38;5;245"; # base1

# Backgrounds (48;5;... is for background)
COLORS["solar_bg_dark"]     = "48;5;235"; # base02
COLORS["solar_bg_darkest"]  = "48;5;234"; # base03
COLORS["solar_bg_light"]    = "48;5;254"; # base2
COLORS["solar_bg_lightest"] = "48;5;230"; # base3

# Pre-combined "Decent" Highlight Styles ✨
# (Using solar_bg_dark as the background)
COLORS["highlight_yellow"]  = "48;5;235;38;5;136"
COLORS["highlight_orange"]  = "48;5;235;38;5;166"
COLORS["highlight_red"]     = "48;5;235;38;5;160"
COLORS["highlight_magenta"] = "48;5;235;38;5;161"
COLORS["highlight_violet"]  = "48;5;235;38;5;61"
COLORS["highlight_blue"]    = "48;5;235;38;5;33"
COLORS["highlight_cyan"]    = "48;5;235;38;5;37"
COLORS["highlight_green"]   = "48;5;235;38;5;106"
COLORS["highlight_inverted"]= "48;5;245;38;5;235" # Dark text on light background
}