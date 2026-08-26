#!/usr/bin/env python3
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Weather for waybar + hyprlock, via wttr.in (no scraping, stdlib only).
# Outputs waybar JSON on stdout and writes ~/.cache/.weather_cache for hyprlock.

import json
import os
import urllib.request

WEATHER_URL = "https://wttr.in/?format=j1"

weather_icons = {
    "sunnyDay": "󰖙",
    "clearNight": "󰖔",
    "cloudyFoggyDay": "",
    "cloudyFoggyNight": "",
    "rainyDay": "",
    "rainyNight": "",
    "snowyIcyDay": "",
    "snowyIcyNight": "",
    "severe": "",
    "default": "",
}

SUNNY = {113}
CLOUDY = {116, 119, 122, 143, 248, 260}
RAIN = {176, 179, 182, 185, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359, 362, 365, 368, 371, 374, 377}
SNOW = {227, 230, 323, 326, 329, 332, 335, 338, 350}
SEVERE = {200, 386, 389, 392, 395}


def category(code, isday):
    if code in SUNNY:
        return "sunnyDay" if isday else "clearNight"
    if code in CLOUDY:
        return "cloudyFoggyDay" if isday else "cloudyFoggyNight"
    if code in SNOW:
        return "snowyIcyDay" if isday else "snowyIcyNight"
    if code in RAIN or code in SEVERE:
        return "rainyDay" if isday else "rainyNight"
    return "default"


def fetch():
    req = urllib.request.Request(WEATHER_URL, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode())


def main():
    try:
        data = fetch()
        cc = data["current_condition"][0]
        today = data["weather"][0]
    except Exception:
        print(json.dumps({
            "text": "󰂳 ?", "alt": "error",
            "tooltip": "Weather unavailable", "class": "default",
        }))
        return

    code = int(cc.get("weatherCode", "0"))
    isday = cc.get("isday", "1") == "1"
    status = cc.get("weatherDesc", [{}])[0].get("value", "Unknown")
    icon_key = category(code, isday)
    icon = weather_icons.get(icon_key, weather_icons["default"])
    temp = cc.get("temp_C", "?")
    feels = cc.get("FeelsLikeC", temp)
    tmin, tmax = today.get("mintempC", "?"), today.get("maxtempC", "?")
    wind = cc.get("windspeedKmph", "?")
    humidity = cc.get("humidity", "?")
    visibility = cc.get("visibility", "?")

    tooltip = (
        f"\t\t<span size=\"xx-large\">{temp}</span>\t\t\n"
        f"<big> {icon}</big>\n"
        f"<b>{status}</b>\n"
        f"<small>Feels like {feels}c</small>\n\n"
        f"<b>  {tmin}     {tmax}</b>\n"
        f"  {wind} km/h\t  {humidity}%\n"
        f"  {visibility} km"
    )

    out = {"text": f"{icon} {temp}°", "alt": status, "tooltip": tooltip, "class": icon_key}
    print(json.dumps(out))

    simple = (
        f"{icon}  {status}\n"
        f"  {temp}° (Feels like {feels}°)\n"
        f"  {wind} km/h\n"
        f"  {humidity}%\n"
        f"  {visibility} km\n"
    )
    try:
        with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as f:
            f.write(simple)
    except Exception:
        pass


if __name__ == "__main__":
    main()
