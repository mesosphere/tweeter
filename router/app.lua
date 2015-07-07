local cjson = require "cjson"

resp = ngx.location.capture('/v1/services/_oinker._tcp.marathon.mesos')

backends = cjson.decode(resp.body)
backend = backends[1]
ngx.var.target = "http://" .. backend['ip'] .. ":"  .. backend['port']
