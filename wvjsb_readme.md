
# 消息

* proxy断开消息,from字段不存在

   ```json
    {
    }
   ```

* client连接消息

   ```json
    {
        "type":"connect",
        "from":"guid(32 chars)",
        "parameter":{}
    }
   ```

* client断开消息

   ```json
    {
        "type":"disconnect",
        "from":"guid(32 chars)"
    }

   ```

* ack消息

   ```json
    {
        "id":"request id",
        "type":"ack",
        "from":"guid(32 chars)",
        "to":"namespace",
        "parameter":"response",
        "error":{
            "domain":"error domain",
            "code":100,
            "description":"error description",
        }
    }
   ```

* cancel消息

   ```json
    {
        "id":"request id",
        "type":"cancel",
        "from":"guid(32 chars)",
        "to":"namespace"
    }
   ```