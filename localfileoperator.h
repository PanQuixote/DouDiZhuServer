#ifndef LOCALFILEOPERATOR_H
#define LOCALFILEOPERATOR_H

#include <QObject>

#include <QFile>
#include <QJsonObject>
#include <QJsonDocument>
#include <QDebug>

class LocalFileOperator : public QObject
{
  Q_OBJECT

public:
  explicit LocalFileOperator(QObject *parent = nullptr);

  Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
  QString source() {return m_source;}
  void setSource(const QString &path)
  {
      if(m_source != path)
      {
          m_source  = path;
          emit sourceChanged(path);
      }
  }

signals:
  void sourceChanged(const QString &path);

public slots:

  QString readFile(QString file_name = "");

  QJsonObject readJsonFile(QString file_name = "");

  bool writeJsonFile(QJsonObject content_obj, QString file_name = "");

  bool writeFile(QString content_string, QString file_name = "");

  QJsonObject stringToJson(const QString& str);

  QString jsonToString(const QJsonObject& json,
                       enum QJsonDocument::JsonFormat format = QJsonDocument::Indented);  //Indented or Compact

  QString getCurrentPath();

  bool isJsonString(const QString &str);

private:
  QString m_source;

};

#endif // LOCALFILEOPERATOR_H
