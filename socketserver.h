#ifndef SERVER_H
#define SERVER_H

#include <Winsock2.h>
#include <windows.h>

#include <list>  
#include <string>

#include <QObject>

#pragma comment (lib, "ws2_32.lib")

using namespace std;

#define IP_BUF_SIZE 129

#define SERVER_PORT 8888
#define MSG_BUF_SIZE 20480

#define MAX_CLIENT_COUNT 3

// how to use it:
// Server s;
// s.start();
// do something in handleMessage();

class ClientManager: public QObject
{
  Q_OBJECT
public:
    ClientManager() {
        clearClientInfo();
    }

    int clientCount() {
        return m_clientCount;
    }

    bool addClient(SOCKET s, char* ip) {

        if (m_clientCount < MAX_CLIENT_COUNT) {
            m_clientCount++;
            for (int i = 0; i < MAX_CLIENT_COUNT; i++) {
                if (m_valid[i] != true) {
                    m_socket[i] = s;
                    strcpy_s(m_ip[i], ip);
                    m_valid[i] = true;
                    return true;
                }
            }
        }

        return false;
    }

    bool deleteClient(SOCKET s) {
        for (int i = 0; i < MAX_CLIENT_COUNT; i++) {
            if (m_socket[i] == s) {
                m_valid[i] = false;
                m_clientCount--;
                return true;
            }
        }

        return false;
    }

    int socketIndex(SOCKET s) {
        for (int i = 0; i < MAX_CLIENT_COUNT; i++) {
            if (m_socket[i] == s) {
                return i;
            }
        }

        return -1;
    }

    SOCKET getSocket(int index) {
        if (index >= 0 && index < MAX_CLIENT_COUNT) {
            return m_socket[index];
        }

        return -1;
    }

    bool isValid(int index) {
        if (index >= 0 && index < MAX_CLIENT_COUNT) {
            return m_valid[index];
        }

        return false;
    }

    void clearClientInfo() {

        m_clientCount = 0;
        for (int i = 0; i < MAX_CLIENT_COUNT; i++) {
            m_socket[i] = -1;
            m_valid[i] = false;
            memset(m_ip[i], 0, sizeof(m_ip[i]));
        }
    }

private:
    int m_clientCount;

    SOCKET m_socket[MAX_CLIENT_COUNT];

    char m_ip[MAX_CLIENT_COUNT][IP_BUF_SIZE];

    bool m_valid[MAX_CLIENT_COUNT];


};


class SocketServer: public QObject
{
  Q_OBJECT
public:
    SocketServer(bool start_after_init = false,
                 bool block_to_wait_enter_instruct = true);
    ~SocketServer();
    SocketServer(const SocketServer &) = delete;
    SocketServer & operator=(const SocketServer &) = delete;

signals:
    void getMessageFromClient(QString msg, int sender_socket);

    void clientConnected(int client_socket);

    void clientDisconnected(int client_socket);

public slots:

  bool init();

  void start(bool block_to_wait_enter_instruct = true);

  bool sendMessage(string msg, int receiver_socket = -1);

  bool sendMessage(QString msg_q, int receiver_socket = -1);

  bool broadcastMessage(string msg);

  int handleMessage(string msg, int sender_socket);

  bool executeInstruct(QString instruct_str);

  int clientCount() {
    return client_manager.clientCount();
  }

  bool addClient(int s, char* ip) {
    return client_manager.addClient(s, ip);
  }

  bool deleteClient(int s) {
    return client_manager.deleteClient(s);
  }

  int getSocket(int index) {
    return client_manager.getSocket(index);
  }

  bool isValid(int index) {
    return client_manager.isValid(index);
  }

  int socketIndex(int s) {
    return client_manager.socketIndex(s);
  }

  void clearClientInfo() {
    client_manager.clearClientInfo();
  }

public:
  WORD winsock_ver;
  WSADATA wsa_data;
  SOCKET sock_svr;
  SOCKET sock_clt;
  HANDLE h_thread;
  SOCKADDR_IN addr_svr;
  SOCKADDR_IN addr_clt;
  int ret_val;
  int addr_len;
  char buf_ip[IP_BUF_SIZE];

  ClientManager client_manager;

private:

  void WaitForClient();
};

// used to be thread's arg
class ThreadArg {
public:
	ThreadArg(SocketServer* pObj, int socket)
		:m_pObj(pObj), m_socket(socket)
	{

	}
public:
	SocketServer* m_pObj;
	int m_socket;
};

#endif
