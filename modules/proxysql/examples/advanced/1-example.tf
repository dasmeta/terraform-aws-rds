module "this" {
  source = "../../"

  name = "proxysql-advanced"

  configs = {
    mysql = {
      server_version = "8.0.37"
      ports          = [3306, 3307]
      monitor = { # will monitor each server backend status
        enabled  = true
        username = "root"
        password = "root"
      }
    }
    admin = {
      user     = "proxysqladmin"
      password = "<proxysqladmin-pass-here>"
    }

    readWriteSplit = true # we set this to have query rules to split read and write queries

    servers = [
      {
        hostname  = "mysql.localhost"
        is_writer = true
      },
      {
        hostname  = "mysql.localhost"
        is_writer = false
      }
    ]

    users = [{
      username = "root"
      password = "root"
    }]

    rules = [
      {
        match_digest = "^select .* from test$" # routes digest matched 3306 port coming queries to hostgroup=0(write hostgroup) with caching for 100 seconds
        digest       = "0x38DF1D37B3136F42"
        cache_ttl    = 100000
        proxy_port   = 3306
      },
      {
        digest     = "0xB99A00381BD4F14D" # matches to match_digest="^select * from test1$", routes 3307 queries to writes hostgroup(destination_hostgroup = 0) and also caching for 100 seconds
        cache_ttl  = 100000
        proxy_port = 3307
      },
      {
        match_digest = "^SELECT .* FROM test2$" # routes digest pattern matched queries from all proxy/mysql ports(in this case 3306 and 3307) to write hostgroup(destination_hostgroup = 0) with caching 100 seconds
        cache_ttl    = 100000
      },
      {
        match_digest          = "^SELECT .* FROM test3$" # routes digest pattern matched queries from all proxy/mysql ports(in this case 3306 and 3307) to read hostgroup with caching 100 seconds
        cache_ttl             = 100000
        destination_hostgroup = 1
      },
      {
        match_pattern         = "^SELECT .* FROM test4$" # routes regex pattern(digest pattern and regex pattern have differences for example regex supports same query different casing) matched queries from all proxy/mysql ports(in this case both 3306 and 3307) to read hostgroup with caching 100 seconds
        cache_ttl             = 100000
        destination_hostgroup = 1
      },
      {
        match_digest = "." # routes all queries coming to 3306 port to write hostgroup(destination_hostgroup=0 by default) without caching
        proxy_port   = 3306
      }
    ]

  }
}
