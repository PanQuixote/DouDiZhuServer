#include "localfileoperator.h"

LocalFileOperator::LocalFileOperator(QObject *parent) : QObject(parent)
{
  m_source = "";
}

QString LocalFileOperator::readFile(QString file_name)
{
  if (file_name == "") {
    file_name = m_source;
  }

  QFile file(file_name);
  if (file.open((QIODevice::ReadOnly | QIODevice::Text)) == true) {
    QByteArray array = file.readAll();
    QString str = QString(array);

    return str;
  } else {
    return "";
  }
}

QJsonObject LocalFileOperator::readJsonFile(QString file_name)
{
  if (file_name == "") {
    file_name = m_source;
  }

  QFile file(file_name);
  if(!file.open(QIODevice::ReadOnly | QIODevice::Text))
  {
    return QJsonObject();
  }

  QByteArray allData = file.readAll();
  if(allData.isEmpty()) {
    return QJsonObject();
  }

  QJsonParseError json_error;
  QJsonDocument jsonDoc(QJsonDocument::fromJson(allData, &json_error));
  if(json_error.error != QJsonParseError::NoError || jsonDoc.isObject() != true)
  {
    return QJsonObject();
  }

  QJsonObject rootObj = jsonDoc.object();
  if(file.isOpen()) {
    file.close();
  }

  return rootObj;
}

bool LocalFileOperator::writeJsonFile(QString file_name, QJsonObject content_obj)
{
  return writeFile(file_name, jsonToString(content_obj));
}

bool LocalFileOperator::writeFile(QString file_name, QString content_string)
{
  if (file_name == "") {
    file_name = m_source;
  }

  QFile file(file_name);
  if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    file.write(content_string.toUtf8());
    file.close();
    return true;
  }

  if(file.isOpen()) {
    file.close();
  }

  return false;
}

QJsonObject LocalFileOperator::stringToJson(const QString &str)
{
  QJsonObject obj;

  QJsonParseError err;
  QJsonDocument doc = QJsonDocument::fromJson(str.toUtf8(), &err);
  if (err.error == QJsonParseError::NoError)
  {
    if (doc.isObject())
    {
      obj = doc.object();
    }
  }
  return obj;
}

QString LocalFileOperator::jsonToString(const QJsonObject &json, enum QJsonDocument::JsonFormat format)
{
  return QString(QJsonDocument(json).toJson(format));
}


