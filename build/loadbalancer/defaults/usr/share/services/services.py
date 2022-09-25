#!/usr/bin/python3

import os
import web
import json
import time
import socket
import subprocess
import fcntl
import select

from web.httpserver import StaticMiddleware
from datetime import datetime
from jinja2 import Template


class icon:
    def GET(self):
        raise web.seeother(
            f"https://{os.environ['FQDN']}/services-static/img/spoon-ok-0.svg"
        )


class status:
    def GET(self):
        #param = web.input()
        return status_page(global_data)


class manifest:
    def GET(self):
        context = {}
        web.header('Content-Type', 'text/cache-manifest')
        template = """CACHE MANIFEST
/services/status
/services-static/*
        """
        return Template(template).render(context)


class message:
    def GET(self):
        web.header('Content-Type', 'application/json')

        if int((datetime.now() - global_data['now']).total_seconds()) >= 1:
            global_data['now'] = datetime.now()

            pms = os.environ['PMS_ENABLED'].split(',')
            services = [
                'frontend',
                'backend', 'beat', 'worker',
                'public',
                *pms,
                'database','datastore'
            ]

            if 'services' not in global_data:
                global_data['services'] = {}

            if 'last_message' not in global_data:
                global_data['last_message'] = ''

            missing = False
            message = False

            for _service in services:
                if f'mf_{_service}' not in global_data['services']:
                    global_data['services'][f'mf_{_service}'] = {
                        'message': '',
                        'node': '',
                        'container': '',
                        'missing': True,
                    }

                # missing
                nodes = len(get_nodes(_service))
                global_data['services'][f'mf_{_service}']['missing'] = (nodes < 1)
                global_data['services'][f'mf_{_service}']['nodes' ] = nodes

                if global_data['services'][f'mf_{_service}']['missing']:
                    global_data['need_reload'] = True
                    missing=True

                if global_data['services'][f'mf_{_service}']['message']:
                    message = True

                global_data['ok'] = False
                if not message:
                    if missing:
                        global_data['need_reload'] = True
                    else:
                        if global_data['need_reload']:
                            reload_haproxy()
                            global_data['need_reload'] = False
                        global_data['ok'] = True

        return json.dumps({
            'last_message': global_data['last_message'],
            'services': global_data['services'],
            'ok': global_data['ok']
        })

    def POST(self):
        data = json.loads(web.data())
        make_global_data(data)


class reconfigure:
    def POST(self):
        data = {
            'text': 'reconfigure',
            'service': os.environ['SERVICE'],
            'node': os.environ['NODE'],
            'container': os.environ['HOSTNAME']
        }

        make_global_data(data)
        config_haproxy()
        reload_haproxy()

        time.sleep(1)
        data['text'] = ''
        make_global_data(data)


def make_global_data(data):
    global_data['ok'] = False

    if 'service' in data:
        if data['service'] not in global_data['services']:
            global_data['services'][data['service']] = {
                'message': '',
                'node': '',
                'container': '',
                'missing': True
            }

        if 'text' in data:
            global_data['services'][data['service']]['message'] = data['text']
            global_data['last_message'] = data['service']
        if 'node' in data:
            global_data['services'][data['service']]['node'] = data['node']
        if 'container' in data:
            global_data['services'][data['service']]['container'] = data['container']


def status_page(context):
    template = """
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="user-scalable=no,initial-scale=1,maximum-scale=1,minimum-scale=1,width=device-width">
    <title>Status | Migasfree</title>

<style type="text/css">
.tooltip {
  position: relative;
  display: inline-block;
  border-bottom: 1px dotted black;
}

.tooltip .tooltiptext {
  visibility: hidden;
  width: 120px;
  background-color: #555;
  color: #fff;
  text-align: center;
  border-radius: 6px;
  padding: 5px 0;
  position: absolute;
  z-index: 1;
  bottom: 125%;
  left: 50%;
  margin-left: -60px;
  opacity: 0;
  transition: opacity 0.3s;
}

.tooltip .tooltiptext::after {
  content: "";
  position: absolute;
  top: 100%;
  left: 50%;
  margin-left: -5px;
  border-width: 5px;
  border-style: solid;
  border-color: #555 transparent transparent transparent;
}

.tooltip:hover .tooltiptext {
  visibility: visible;
  opacity: 1;
}
</style>

    <script src="/services-static/js/jquery-1.11.1.min.js" type="text/javascript"></script>

    <script type="text/javascript">
      function sleep(time) {
        return new Promise((resolve) => setTimeout(resolve, time));
      }

      let time = +new Date;
      let circles = "#loadbalancer, #frontend, #backend, #beat, #worker, #public, #pms, #database, #datastore";
      let serv = ""

      $(document).ready(function () {
        setInterval(function () {
          let now = +new Date;
          let retraso = parseInt((now - time) / 1000);

          if (retraso > 1.5) {
            $("#message").text('disconnected');
            $("#spoon").attr("href", "/services-static/img/spoon-disconnect.svg");
            $(circles).hide(200);
            $("#loadbalancer").show(200);
            $("#loadbalancer").attr('fill', 'red');
            $("#start").hide(200);
          }

          $.ajax({
            url: '/services/message',
            success: function (data) {
              function missing_pms() {
                let _missing = false;
                let _message = false;
                let _service = "";
                let _nodes = 0;

                for (const [key, value] of Object.entries(data['services'])) {
                  if (key.startsWith('mf_pms-')) {
                    if (data['services'][key]["missing"]) {
                      _missing = true;
                      _service = key; // last service found in data
                    }
                    if (data['services'][key]["message"] != "" ) {
                      _message = true;
                      _service = key; // last service found in data
                    }
                    _nodes += data['services'][key]["nodes"]
                  }
                }
                if (_message) {
                  _missing = false;
                }

                if (_missing) {
                  $("#pms").attr('fill', 'red');
                  $("#pms").show(500);
                } else if (_message) {
                  $("#pms").attr('fill', 'orange');
                  $("#pms").hide(500);
                  $("#pms").show(500);
                } else {
                  $("#pms").attr('fill', '#a9dfbf'); // GREEN
                  $("#pms").show(500);
                }

                if (_nodes < 2) {
                  $("#nodes_pms").text("");
                } else {
                  $("#nodes_pms").text(_nodes);
                }

                return _service;
              }

              function missing(id) {
                let services = data["services"];
                let _missing = false;
                let _message = "";
                let _nodes = 0;

                if (id == 'loadbalancer') {
                  _missing = false;
                  _message = services[`core_${id}`]["message"];
                  _nodes = 1;
                } else {
                  _missing = services[`mf_${id}`]["missing"];
                  _message = services[`mf_${id}`]["message"];
                  _nodes = services[`mf_${id}`]["nodes"];
                }

                if (_missing) {
                  $(`#${id}`).attr('fill', 'red');
                  $(`#${id}`).show(500);
                } else if (_message != "") {
                  $(`#${id}`).attr('fill', 'orange');
                  $(`#${id}`).hide(500);
                  $(`#${id}`).show(500);
                } else {
                  $(`#${id}`).attr('fill', '#a9dfbf'); // GREEN
                  $(`#${id}`).show(500);
                }

                if (_nodes < 2) {
                  $(`#nodes_${id}`).text("");
                } else {
                  $(`#nodes_${id}`).text(_nodes);
                }
              }

              time = +new Date;

              missing("loadbalancer");
              missing("frontend");
              missing("backend");
              missing("beat");
              missing("worker");
              missing("public");
              missing("database");
              missing("datastore");

              let message_pms = missing_pms();
              let message_from = "";
              let message_serv = `mf_${serv}`;

              if (serv == "") {
                message_serv = data['last_message'];
              } else if (serv == "loadbalancer") {
                message_serv = `core_${serv}`;
              }

              if (typeof(data) != "undefined") {
                if (serv == "pms" && message_pms != "") {
                  message = data['services'][message_pms]['message'];
                  message_serv = message_pms;
                  message_from = `${data['services'][message_pms]['container']}@${data['services'][message_pms]['node']}`;
                } else {
                  message = data['services'][message_serv]['message'];
                  message_from = `${data['services'][message_serv]['container']}@${data['services'][message_serv]['node']}`;
                }
              }

              let sprite;
              if (data['ok']) {
                sprite = parseInt((now / 1000) % 2);
                $("#spoon").attr("href", `/services-static/img/spoon-ok-${sprite}.svg`);
                $(".bocadillo").hide(200);
                $("#start").show(100);
              } else if (message_serv in data['services'] && data['services'][message_serv]['missing']) {
                sprite = parseInt((now / 1000) % 2);
                $("#spoon").attr("href", `/services-static/img/spoon-starting-${sprite}.svg`);
                $(".bocadillo").hide(200);
                $("#start").hide(200);
              } else {
                sprite = parseInt((now / 1000) % 3);
                $("#spoon").attr("href", `/services-static/img/spoon-checking-${sprite}.svg`);
                $(".bocadillo").show(200);
                $("#start").hide(200);
              }

              if (message == "") {
                $("#message").text('ready');
              } else {
                $("#message").text(message);
              }

              $("#message_serv").text(message_serv);
              $("#message_from").text(message_from);

              if (! location.pathname.startsWith('/services/status')) {
                if (data["ok"]) {
                  $(location).attr('href', location.href);
                }
              }
            },
          });
        }, 1000);
      });

      $(window).load(function () {
        // force download image
        $("#spoon-disconnected").attr('href', '/services-static/img/spoon-disconnect.svg');

        $("#start").hide(1)
        $("#start").attr('href', '/services-static/img/start.svg');

        $(circles).attr('fill', 'orange');
        $(circles).hide(200);
        $("#spoon").hide(200);
        $("#spoon").attr('href', '/services-static/img/spoon-welcome.svg');
        $("#spoon").show(100);

        const welcome = ["salut!", "Hi!", "¡hola!", "¡hola, co!", "kaixo!", "ola!", "Hallo!"];
        $("#message").text(welcome[Math.floor(Math.random() * 7)]);
      });
    </script>
  </head>
  <body>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="20 70 160 70">
      <image href="/services-static/img/background.svg" x=30 y=50 height="120" width="120" />

      <-- force download file spoon-disconnect.svg-->
      <image id="spoon-disconnected" href="/" x=0 y=0 height="0" width="0" />

      <image id="spoon" href="/" x=155 y=120 height="20" width="20" />

      <!-- bocadillo -->
      <rect class="bocadillo" x="145" y="90" width="33" height="28" rx="2" ry="2" fill="#FFFF99" />
      <line class="bocadillo" x1="160" y1="121" x2="158" y2="117" stroke="#FFFF99" />

      <switch>
        <foreignObject x="147.5" y="90" width="30" height="25.5" font-size="2">
          <p class="bocadillo" id="message"> one moment, please </p>
        </foreignObject>
      </switch>

      <switch>
        <foreignObject x="147.5" y="111.5" width="30" height="4" font-size="1.6">
          <p class="bocadillo" id="message_serv">  </p>
        </foreignObject>
      </switch>

      <switch>
        <foreignObject x="147.5" y="113.9" width="30" height="4" font-size="1.2">
          <p class="bocadillo" id="message_from">  </p>
        </foreignObject>
      </switch>

      <image id="start" href="/" x=155 y=101 height="10" width="10" onclick="$(location).attr('href','/');" />

      <circle id="loadbalancer" cx="37.5" cy="110" r="1.5" fill="orange"
        onmouseenter="serv='loadbalancer';"
        onmouseout="serv='';" />

      <circle id="frontend" cx="60" cy="110" r="1.5" fill="orange"
        onmouseenter="serv='frontend';"
        onmouseout="serv='';" />
      <text id="nodes_frontend" x="60" y="111" text-anchor="middle" font-size="3"></text>

      <circle id="backend" cx="84" cy="92" r="1.5" fill="orange"
        onmouseenter="serv='backend';"
        onmouseout="serv='';" />
      <text id="nodes_backend" x="84" y="93" text-anchor="middle" font-size="3"></text>

      <circle id="beat" cx="84" cy="110" r="1.5" fill="orange"
        onmouseenter="serv='beat';"
        onmouseout="serv='';" />
      <text id="nodes_beat" x="84" y="111" text-anchor="middle" font-size="3"></text>

      <circle id="worker" cx="84" cy="128" r="1.5" fill="orange"
        onmouseenter="serv='worker';"
        onmouseout="serv='';" />
      <text id="nodes_worker" x="84" y="129" text-anchor="middle" font-size="3"></text>

      <circle id="public" cx="103" cy="100" r="1.5" fill="orange"
        onmouseenter="serv='public';"
        onmouseout="serv='';" />
      <text id="nodes_public" x="103" y="101" text-anchor="middle" font-size="3"></text>

      <circle id="pms" cx="103" cy="119" r="1.5" fill="orange"
        onmouseenter="serv='pms';"
        onmouseout="serv='';" />
      <text id="nodes_pms" x="103" y="120" text-anchor="middle" font-size="3"></text>

      <circle id="database" cx="128" cy="101" r="1.5" fill="orange"
        onmouseenter="serv='database';"
        onmouseout="serv='';" />

      <circle id="datastore" cx="128" cy="123" r="1.5" fill="orange"
        onmouseenter="serv='datastore';"
        onmouseout="serv='';" />
    </svg>
  </body>
</html>
"""
    return Template(template).render(context)


def notfound():
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
    pms_enabled = os.environ['PMS_ENABLED']
    extensions = []
    _code, _out,_err = execute(
        'curl -X GET backend:8080/api/v1/public/pms/',
        interactive=False
    )
    if _code == 0:
        try:
            all_pms = json.loads(_out.decode('utf-8'))
        except:
            return ''.join(set(extensions))
        for pms in all_pms:
            if f'pms-{pms}' in pms_enabled:
                for extension in all_pms[pms]['extensions']:
                    extensions.append(extension)

    return list(set(extensions))


def config_nginx():
    fileconfig = os.path.join(
        os.environ['MIGASFREE_CONF_DIR'],
        'locations.d',
        'external-deployments.conf'
    )
    template = """
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

    with open(fileconfig, 'w') as f:
        f.write(Template(template).render(
            {'extensions': global_data['extensions']}
        ))


def config_haproxy():
    context = {
        'cerbot': os.environ['HTTPSMODE'] == 'auto',
        'mf_public': get_nodes('public'),
        'mf_backend': get_nodes('backend'),
        'mf_frontend': get_nodes('frontend')
    }

    if len(global_data['extensions']) == 0 and len(context['mf_backend']) > 0:
        global_data['extensions'] = get_extensions()
        if len(global_data['extensions']) > 0:
            config_nginx()

    if len(global_data['extensions']) == 0:
        context['extensions'] = '.deb .rpm'
    else:
        context['extensions'] = '.' + ' .'.join(global_data['extensions'])

    with open('/etc/haproxy/haproxy.template') as f:
        haproxy_template = f.read()

    fileconfig = '/etc/haproxy/haproxy.cfg'
    with open(fileconfig, 'w') as f:
        f.write(Template(haproxy_template).render(context))
        f.write('\n')


def reload_haproxy():
    _code, _out,_err = execute(
        "/usr/bin/reload",
        interactive=False
    )


def get_nodes(service):
    nodes = []
    _code, _out,_err = execute(
        f"dig tasks.{service} | grep ^tasks.{service} | awk '{{print $5}}'",
        interactive=False
    )
    if _code == 0:
        for node in _out.decode('utf-8').replace('\n', ' ').split(' '):
            if node:
                nodes.append(node)

    return nodes


def ckeck_server(host: str,port: int):
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


if __name__ == '__main__':
    urls = (
        '/favicon.ico', 'icon',
        '/services/status/?', 'status',
        '/services/manifest', 'manifest',
        '/services/message', 'message',
        '/services/reconfigure', 'reconfigure',
    )

    global_data = {
        'services': {},
        'message': '',
        'need_reload': True,
        'extensions': [],
        'ok': False,
        'now': datetime.now()
    }

    config_haproxy()

    app = web.application(urls, globals(), autoreload=False)
    app.notfound = notfound
    app.run(servicesStaticMiddleware)
