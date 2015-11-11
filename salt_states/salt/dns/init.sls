{#
Salt Formula by Charles Galey cgaley@nomagic.com
Developed for NMInc
#}
{% if grains['domain'] != 'nminc.co.' %}
{% set myIP = grains['fqdn_ip4'] %}
{% else %}
{% set myIP = salt.network.ip_addrs('eth0', 'cidr="172.31.0.0/16"') %}
{% endif %}

{% if grains['farm_role_index'] == 1 %}

 {% set fqdn = grains['nodename'] %}
 {% set hostname = grains['farm_name'] %}

{% endif %}

{% set myDomain = grains['domain'] %}


set_hosts:
  file.managed:
    - name: /etc/hosts
    - contents: |
        127.0.0.1       {{ grains['farm_name'] }}.{{ myDomain }} localhost
        {{ myIP[0] }}       {{ grains['farm_name'] }}.{{ myDomain }} {{ grains['farm_name'] }}

set_hostname:
  file.managed:
    - name: /etc/hostname
    - contents: "{{ grains['farm_name'] }}"
    
update_hostname:
  cmd.run:
    - name: "hostname -F /etc/hostname"
    - user: root
    - group: root
    - require:
      - file: set_hosts
      - file: set_hostname

update_hostnamectl:
  cmd.run:
    - name: "hostnamectl set-hostname {{ grains['farm_name'] }}"
    - user: root
    - group: root
    - require:
      - file: set_hosts
      - file: set_hostname
