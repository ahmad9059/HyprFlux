// Inspect real Qt plugins without opening a window or changing user settings.
#include <QApplication>
#include <QFile>
#include <QIcon>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPalette>
#include <QProxyStyle>
#include <QStyle>
#include <QStyleFactory>
#include <cstdio>

int main(int argc, char** argv) {
    QApplication app(argc, argv);
    QFile maps("/proc/self/maps");
    maps.open(QIODevice::ReadOnly);
    const auto loaded = maps.readAll();
    QStyle* base = app.style();
    while (auto* proxy = qobject_cast<QProxyStyle*>(base))
        base = proxy->baseStyle();
    QJsonObject data{
        {"qt", qVersion()},
        {"style", app.style()->objectName()},
        {"base_style", base->objectName()},
        {"available_styles", QJsonArray::fromStringList(QStyleFactory::keys())},
        {"window", app.palette().color(QPalette::Window).name()},
        {"text", app.palette().color(QPalette::WindowText).name()},
        {"highlight", app.palette().color(QPalette::Highlight).name()},
        {"icons", QIcon::themeName()},
        {"qt5ct_loaded", loaded.contains("/platformthemes/libqt5ct.so")},
        {"qt6ct_loaded", loaded.contains("/platformthemes/libqt6ct.so")},
        {"kvantum_loaded", loaded.contains("/styles/libkvantum.so")}
    };
    puts(QJsonDocument(data).toJson(QJsonDocument::Compact).constData());
}
