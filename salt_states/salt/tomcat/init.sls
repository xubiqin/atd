{#
Salt Formula by Ian Weaklim weaklim@jpl.nasa.gov ianw@uwyo.edu
Developed for JPL/NASA Summer 2014

Modified by Sophie Wong
#}
tomcat:
  group:
    - present
    - gid: 4000
  user:
    - present
    - uid: 4000
    - groups: 
      - tomcat
    - require:
      - group: tomcat
    - shell: /sbin/nologin
    - createhome: True

apache_tomcat_7_startup:
  service:
    - dead
    - name: tomcat
    - enable: True
    - onlyif: test ! -e /usr/lib/systemd/system/tomcat.service
    - require:
        - file: /usr/lib/systemd/system/tomcat.service
        - user: tomcat
        - group: tomcat

apache_tomcat7_unpack:
  archive:
    - extracted
    - name: /opt/local
    - source: salt://tomcat/files/apache-tomcat-7.0.63.tar.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ pillar['tomcat_home'] }}/webapps

/etc/profile.d/tomcat.sh:
  file.managed:
    - source: salt://tomcat/files/tomcat.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 644

tomcat_sym:
  file.symlink:
    - name: {{ pillar['tomcat_home'] }}
    - target: {{ pillar['tomcat_home'] }}-7.0.63
    - user: tomcat
    - group: tomcat
    - require: 
      - archive: apache_tomcat7_unpack
      - user: tomcat
      - group: tomcat
    - if_missing: {{ pillar['tomcat_home'] }}/webapps
    - recurse:
      - user
      - group

tomcat_owner:
  file.directory:
    - name: {{ pillar['tomcat_home'] }}-7.0.63
    - user: tomcat
    - group: tomcat
    - recurse: 
      - user
      - group

/usr/lib/systemd/system/tomcat.service:
  file.managed:
    - order: 1
    - source: salt://tomcat/files/tomcat.service
    - template: jinja
    - user: root
    - group: root
    - mode: 755

/var/run/tomcat/:
  file.directory:
    - order: 1
    - user: tomcat
    - group: tomcat
    - mode: 644
    - makedirs: True
    - require:
      - user: tomcat
      - group: tomcat


add_tomcat_systemd:
  cmd.run:
    - order: 1
    - name: systemctl daemon-reload && systemctl enable tomcat.service
    - user: root
    - group: root
    - require:
      - file: /usr/lib/systemd/system/tomcat.service

{{ pillar['tomcat_home'] }}/bin/setenv.sh:
  file.managed:
    - order: 1
    - source: salt://tomcat/files/setenv.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - replace: False
    - require:
      - file: tomcat_sym
      - file: /usr/lib/systemd/system/tomcat.service
      - user: tomcat
      - group: tomcat
    
{# This makes tomcat/alfresco use properties files outside of the
   exploded wars. Maybe move to alfresco?
   Sophie Wong 8/26/2014
#}
{% if grains['node_type'] != 'build' %}
add_alfresco_shared_loader:
  module.run:
    - name: file.replace
    - path: {{ pillar['tomcat_home'] }}/conf/catalina.properties
    - pattern: shared.loader=.*$
    - repl: shared.loader=${catalina.base}/shared/classes
{% endif %}
