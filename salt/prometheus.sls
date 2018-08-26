{% if salt.grains.get('osarch').lower() == "x86_64" %}
  {% set osarch="amd64" %}
{% elif salt.grains.get('osarch').lower() == "amd64" %}
  {% set osarch="amd64" %}
{% elif salt.grains.get('osarch').lower() == "i386" %}
  {% set osarch="386" %}  
{% elif salt.grains.get('osarch').lower() == "armhf" %}
  {% set osarch="armv6" %}  
{% elif salt.grains.get('osarch').lower() == "arm64" %}
  {% set osarch="arm64" %}    
{% endif %}

###################################

install_prometheus:
  archive.extracted:
    - name: /usr/local/prometheus/
    - source: https://github.com/prometheus/prometheus/releases/download/v2.3.2/prometheus-2.3.2.{{ grains['kernel'] | lower }}-{{ osarch }}.tar.gz
    - skip_verify: True
    - if_missing: /usr/local/prometheus/prometheus-2.3.2.{{ grains['kernel'] | lower }}-{{ osarch }}

/etc/prometheus:
  file.directory:
    - user: root
    - makedirs: True

### TODO
{# {% set default_ip4_var="unassigned" %}
{% for zz in grains['ipv4'] %}
  {% if not zz.startswith("127") %}
    {% set default_ip4_var="{0}".format(zz) %}
  {% endif %}
{% endfor %} #}

{% if grains['host'] == "firefly" %}
/etc/prometheus/prometheus.yml:
  file.managed:
    - source: salt://prometheus/prometheus-federate.yml
    - user: root
    - mode: 644
    - attrs: ai
{% endif %}

{# /etc/prometheus/prometheus.yml:
  file.managed:
{% if grains['host'] == "firefly" %}
    - source: salt://prometheus/prometheus-federate.yml
   {% else %}
    - source: salt://prometheus/prometheus-targets.yml
    - defaults:
        default_ip4: {{ default_ip4_var }}
    - template: jinja
    - user: root
    - mode: 644
    - attrs: ai 
{% endif %} #}

/usr/local/sbin/prometheus:
  file.symlink:
    - target: /usr/local/prometheus/prometheus-2.3.2.{{ grains['kernel'] | lower }}-{{osarch}}/prometheus

###################################

install_supervisor:
  pkg.installed:    
  {% if salt.grains.get('os_family').lower() == 'freebsd' %}
    - name: "py27-supervisor"
  {% else %}
    - name: "supervisor"
  {% endif %}

{% if salt.grains.get('os_family').lower() == 'freebsd' %}
/usr/local/etc/supervisord.conf:
{% elif salt.grains.get('os').lower() == 'fedora' %}
/etc/supervisord.conf:
{% endif %}
  file.managed:
    - source: salt://prometheus/supervisord-freebsd-fedora.yml
    - user: root
    - mode: 644
    - attrs: ai

/etc/supervisor/conf.d:
  file.directory:
    - user: root
    - makedirs: True  

{% if salt.grains.get('os_family').lower() in ['freebsd'] or salt.grains.get('os').lower() in ['fedora'] %}
supervisord:
{% else %}
supervisor:
{% endif %}
  service.running:
    - enable: True
    - reload: True
    {% if salt.grains.get('os_family').lower() == 'freebsd' %}
    - watch:      
      - pkg: "py27-supervisor"
    {% endif %}

###################################


/etc/supervisor/conf.d/prometheus.conf:
  file.managed:
    - source: salt://prometheus/prometheus-supervisor.yml

/etc/supervisor/conf.d/node_exporter.conf:
  file.managed:
    - source: salt://prometheus/node_exporter-supervisor.yml

###################################

{% if salt.grains.get('kernel').lower() == "linux" %}
  
install_node_exporter:
  archive.extracted:
    - name: /usr/local/node_exporter/    
    - source: https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.{{ grains['kernel'] | lower }}-{{ osarch }}.tar.gz
    - skip_verify: True
    - if_missing: /usr/local/node_exporter/node_exporter-0.16.0.{{ grains['kernel'] | lower }}-{{ osarch }}

/etc/node_exporter:
  file.directory:
    - user: root
    - makedirs: True

/usr/local/sbin/node_exporter:
  file.symlink:
    - target: /usr/local/node_exporter/node_exporter-0.16.0.{{ grains['kernel'] | lower }}-{{ osarch }}/node_exporter

{% endif %}

###################################

{% if grains['host'] == "firefly" %}
  
install_alertmanager:
  archive.extracted:
    - name: /usr/local/alertmanager/    
    - source: https://github.com/prometheus/alertmanager/releases/download/v0.15.2/alertmanager-0.15.2.{{ grains['kernel'] | lower }}-{{ osarch }}.tar.gz
    - skip_verify: True
    - if_missing: /usr/local/alertmanager/alertmanager-0.15.2.{{ grains['kernel'] | lower }}-{{ osarch }}

/etc/alertmanager:
  file.directory:
    - user: root
    - makedirs: True

/usr/local/sbin/alertmanager:
  file.symlink:
    - target: /usr/local/alertmanager/alertmanager-0.15.2.{{ grains['kernel'] | lower }}-{{ osarch }}/alertmanager

/etc/alertmanager/config.yml:
  file.managed:
    - source: salt://prometheus/alertmanager-config.yml    
    - user: root
    - mode: 644
    - attrs: ai

/etc/supervisor/conf.d/alertmanager.conf:
  file.managed:
    - source: salt://prometheus/alertmanager-supervisor.yml

/etc/alertmanager/am-alerts.yml:
  file.managed:
    - source: salt://prometheus/am-alerts.yml

{% endif %}

###################################

supervisord_restart_all:
  cmd.run:
    - name: "supervisorctl update && supervisorctl restart all"

