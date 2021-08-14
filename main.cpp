#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "socketserver.h"
#include "localfileoperator.h"

int main(int argc, char *argv[])
{
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

  QGuiApplication app(argc, argv);

  qmlRegisterType<SocketServer>("qt.SocketServer", 1, 0, "SocketServer");
  qmlRegisterType<LocalFileOperator>("qt.LocalFileOperator", 1, 0, "LocalFileOperator");

  QQmlApplicationEngine engine;
  const QUrl url(QStringLiteral("qrc:/main.qml"));
  QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                   &app, [url](QObject *obj, const QUrl &objUrl) {
    if (!obj && url == objUrl)
      QCoreApplication::exit(-1);
  }, Qt::QueuedConnection);
  engine.load(url);

  return app.exec();
}
