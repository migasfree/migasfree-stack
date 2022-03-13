#!/usr/bin/python3

import web
import time
from web.httpserver import StaticMiddleware

import json
import platform
from jinja2 import Template
import subprocess
import os
import socket
import _thread

with open("/etc/haproxy/haproxy.template") as f:
    haproxy_template = f.read()

urls = (
    '/favicon.ico', 'icon',
    '/services/status/?', 'status',
    '/services/manifest', 'manifest',
    '/services/message', 'message',
    '/services/reconfigure', 'reconfigure',
)

global_data = {'message':'', 'need_reload': True,"extensions": []}

fileconfig = "/etc/haproxy/haproxy.cfg"

def check_running():
    while True:
        if not ckeck_server2(os.environ['FQDN'], 443):
            config_haproxy()
            reload_haproxy()
        
        time.sleep(10)


class icon:
    def GET(self):
        #raise web.seeother("/services-static/img/favicon.png")
        raise web.seeother("https://{}/services-static/img/spoon-ok-0.svg".format(os.environ['FQDN']))

class status:
    def GET(self):
        param = web.input()
        return status_page(global_data)

class manifest:
    def GET(self):
        context={}
        web.header('Content-Type', 'text/cache-manifest')
        template = """CACHE MANIFEST
/services/status
/services-static/*
        """
        return Template(template).render(context)


class message:
    def GET(self):

        second=int(time.time() % 60)  # 0-59
        web.header('Content-Type', 'application/json')
        msg = global_data["message"]
        pms=os.environ['PMS_ENABLED'].split(',')
        services=['datastore', 'database','backend','beat','worker','frontend','public', *pms]
        if not msg:
            missing = []
            #check services
            for service in services:
                if len(get_nodes(service)) < 1:
                    missing.append(service)

            if len(missing)>0:
                msg = "waiting to {}".format(", ".join(missing))
                icon = "spoon-checking-{}.svg".format(second % 3)
                gear =  "search.svg"
                global_data["need_reload"]=True
            else:
                if global_data["need_reload"]:
                    reload_haproxy()
                    global_data["need_reload"]=False

                global_data["message"] = ""
                """
                global_data["service"] = ""
                global_data["container"] = ""
                """
                msg = "All services are running"
                icon = global_data["icon"] = "spoon-ok-{}.svg".format(second % 2)
                gear =  "gear-{}.svg".format(second % 3)

        else:
            icon = global_data["icon"] = "spoon-starting-{}.svg".format(second % 2)
            gear =  "tools.svg"
        
        return json.dumps({
                "message": msg, 
                "icon": icon, 
                "gear": gear,
                "tooltip": "Spoon"
            })



    def POST(self):
        param = web.input()
        if 'text' in param:
            global_data["message"] = param.text.split(";")[0]
        """
        if 'container' in param:
            global_data["container"] = param.container
        if 'service' in param:
            global_data["service"] = param.service
        """

class reconfigure:
    def POST(self):
        config_haproxy()
        reload_haproxy()


def status_page(context):
    template="""
<!DOCTYPE html>


<html manifest="/services/manifest">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

        <title>Status of services | Migasfree</title>
        <script src="/services-static/js/jquery-1.11.1.min.js" type="text/javascript"></script>



        <script type="text/javascript">
            function sleep (time) {
                return new Promise((resolve) => setTimeout(resolve, time));
            }

            var time = +new Date;

            $(document).ready(function() {
                
                setInterval(function() {
                    var now = +new Date;
                    var retraso = parseInt((now-time)/1000);
                    if ( retraso > 1.5) {

                        $("#gear").attr("src","/services-static/img/disconnect.svg");
                        $("#message").text('disconnected');
                        $("#status_image").attr("src","/services-static/img/spoon-disconnect.svg");
                        $("#status_image").attr('title', "load balancer not found")

                    }


                    $.ajax({
                        url: '/services/message',
                        success: function(data) {
                            time = +new Date;
                            
                            $("#gear").attr("src","/services-static/img/" + data.gear);
                            $("#message").text(data.message);
                            $("#status_image").attr("src","/services-static/img/" + data.icon);
                            $("#status_image").attr('title', data.tooltip)
                            
                            if ( data.message == "All services are running" ) {
                                $("#image").attr('href',"/");
                            } else {
                                $("#image").removeAttr('href');
                            }

                            if  ( ! location.pathname.startsWith('/services/status') ) {
                                if ( data.message == "All services are running" ) {
                                    $("#message").finish();                                   
                                    $(location).attr('href',location.href);      
                                }   
                            } 
                            
                        },
                    });
                }, 1000);
            });

            $( window ).load( function() {
                $("#gear").attr("src","/services-static/img/disconnect.svg");
                $("#gear").attr("src","/services-static/img/wait.svg");
                $("#status_image").attr("src","/services-static/img/spoon-disconnect.svg");
            });

        </script>

        <style>
            body {
                width: 35em;
                margin: 0 auto;
                font-family: Tahoma, Verdana, Arial, sans-serif;
            }

            .center-div
            {
                position: absolute;
                margin: auto;
                top: -20%;
                right: 0;
                bottom: 0;
                left: 0;
                width: 50%;
                height: 50%;
                border-radius: 40px;
            }

        </style>
    </head>
    <body>

        <div id="box" class="center-div">
            <p> </p>
            <p> </p>
            <div align="center">


                <div align="center">
                    <a id="image">
                        <img id="gear" src="/services-static/img/disconnect.svg"  height="10%" width="10%"> 
                    </a>
                </div>   
                
                <div id="message" align="center" style="font-size: 1.8vw;">
                    please wait
                </div>

                <div align="right"><img id="status_image" src="/services-static/img/spoon-disconnect.svg"  style="padding-right: 20%" height="20%" width="20%"> </div>   

                
            </div>
        </div>
    </body>

</html>
"""
    return Template(template).render(context)



def notfound():
    #raise ServiceUnavailable()
    raise NotFound()

class ServiceUnavailable(web.HTTPError):
    def __init__(self):
        status = '503 Service Unavailable'
        headers = {'Content-Type': 'text/html'}
        data = status_page(global_data)
        web.HTTPError.__init__(self, status, headers, data)

class NotFound(web.HTTPError):
    def __init__(self):
        status = '404 Not Found'
        headers = {'Content-Type': 'text/html'}
        data = status_page(global_data)
        web.HTTPError.__init__(self, status, headers, data)


def execute(cmd, verbose=False, interactive=True):
    """
    (int, string, string) execute(
        string cmd,
        bool verbose=False,
        bool interactive=True
    )
    """
    _output_buffer = ''
    if verbose:
        print(cmd)
    if interactive:
        _process = subprocess.Popen(
            cmd,
            shell=True,
            executable='/bin/bash'
        )
    else:
        _process = subprocess.Popen(
            cmd,
            shell=True,
            executable='/bin/bash',
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE
        )
        if verbose:
            fcntl.fcntl(
                _process.stdout.fileno(),
                fcntl.F_SETFL,
                fcntl.fcntl(
                    _process.stdout.fileno(),
                    fcntl.F_GETFL
                ) | os.O_NONBLOCK,
            )
            while _process.poll() is None:
                readx = select.select([_process.stdout.fileno()], [], [])[0]
                if readx:
                    chunk = _process.stdout.read()
                    if chunk and chunk != '\n':
                        print(chunk)
                    _output_buffer = '%s%s' % (_output_buffer, chunk)
    _output, _error = _process.communicate()
    if not interactive and _output_buffer:
        _output = _output_buffer
    return _process.returncode, _output, _error

def get_extensions():
    pms_enabled=os.environ["PMS_ENABLED"]
    extensions = []
    _code, _out,_err = execute("curl -X GET backend:8080/api/v1/public/pms/",interactive=False)
    if _code == 0:
        try:
            allpms = json.loads(_out.decode("utf-8"))
        except:
            return "".join(set(extensions))
        for pms in allpms:
            if "pms-{}".format(pms) in  pms_enabled:
                for extension in allpms[pms]["extensions"]:
                    extensions.append(extension)
    return list(set(extensions))


def config_nginx():
    fileconfig=os.path.join(os.environ['MIGASFREE_CONF_DIR'], "locations.d", "external-deployments.conf")
    template="""
        # External Deployments. Auto-generated from loadbalancer (in services.py -> config_nginx)
        # ========================================================================
    {% for extension in extensions %}
        location ~* /src/?(.*){{extension}}$ {
        alias /var/migasfree/public/$1{{extension}};
        error_page 404 = @backend;
        }
    {% endfor %}
        # ========================================================================
    """
    with open(fileconfig, "w") as f:
        f.write(Template(template).render({'extensions': global_data['extensions']}))
    

def config_haproxy():
    context = {}

    context["cerbot"] = (os.environ["HTTPSMODE"] == "auto")
    
    if ckeck_server("public",8080):
        context["mf_public"] = get_nodes("public")
    else: 
         context["mf_public"] = []

    if ckeck_server("backend",8080):
        context["mf_backend"] = get_nodes("backend")
        if len(global_data['extensions']) == 0 and len(context["mf_backend"] ) > 0:
            global_data['extensions']=get_extensions()
            if len(global_data['extensions']) > 0:
                config_nginx()

        if  len(global_data['extensions']) == 0:
            context["extensions"] = ".deb .rpm"
        else:
            context["extensions"]  = "."+" .".join(global_data['extensions'])


     # Si no hay backends se asume que tampoco hay frontend
        if ckeck_server("frontend",8080):
            context["mf_frontend"] = get_nodes("frontend")
        else:
            context["mf_frontend"] = []
    else:
        context["mf_public"] = []
        context["mf_frontend"] = []
    
    with open(fileconfig, "w") as f:
        f.write(Template(haproxy_template).render(context))


def reload_haproxy():
    #https://www.haproxy.com/blog/haproxy-1-9-has-arrived/
    _code, _out,_err = execute("echo '@master reload' | socat /var/run/haproxy-master-socket stdio", interactive=False)

def get_nodes(service):
    nodes =[]
    _code, _out,_err = execute("dig tasks.{service}|grep ^tasks.{service}|awk '{{print $5}}'".format(service=service), interactive=False)
    if _code == 0:
        for node in _out.decode("utf-8").replace("\n", " ").split(" "):
            if node:
                nodes.append(node)
    return nodes


def ckeck_server(host: str,port: int):
    return True

def ckeck_server2(host: str,port: int):
    """
    return True
    """
    try:
        args = socket.getaddrinfo(host, port, socket.AF_INET, socket.SOCK_STREAM)
    except:
        return False
    
    for family, socktype, proto, canonname, sockaddr in args:
        s = socket.socket(family, socktype, proto)
        try:
            s.connect(sockaddr)
        except socket.error:
            return False
        else:
            s.close()
            return True
    

class servicesStaticMiddleware(StaticMiddleware):
    def __init__(self, app, prefix='/services-static/'):
        StaticMiddleware.__init__(self, app, prefix)


if __name__ == "__main__":

    _thread.start_new_thread(check_running, ())

    config_haproxy()
    app = web.application(urls, globals(), autoreload=False)
    app.notfound = notfound
    app.run(servicesStaticMiddleware)



