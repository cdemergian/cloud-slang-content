# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
# The Apache License is available at
# http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
# This flow performs a linux command to add a specified user named <user_name>
#
# Inputs:
#   - host - hostname or IP address
#   - root_password - the root password
#   - user_name - the name of the user to verify if exist
#   - user_password - the password to be set for the <user_name>
#   - group_name - optional - the group name where the <user_name> will be added - Default: ''
#   - create_home - optional - if True then a <user_name> folder with be created in <home_path> path
#                              if False then no folder will be created - Default: True
#   - home_path - optional - the path of the home folder - Default: '/home'
#
# Outputs:
#    - returnResult - STDOUT of the remote machine in case of success or the cause of the error in case of exception
#    - standard_out - STDOUT of the machine in case of successful request, null otherwise
#    - standard_err - STDERR of the machine in case of successful request, null otherwise
#    - exception - contains the stack trace in case of an exception
#    - command_return_code - The return code of the remote command corresponding to the SSH channel. The return code is
#                            only available for certain types of channels, and only after the channel was closed
#                            (more exactly, just before the channel is closed).
#	                         Examples: 0 for a successful command, -1 if the command was not yet terminated (or this
#                                      channel type has no command), 126 if the command cannot execute.
# Results:
#    - SUCCESS - add user SSH command was successfully executed
#    - FAILURE - otherwise
####################################################
namespace: io.cloudslang.base.os.linux.users

imports:
  ssh: io.cloudslang.base.remote_command_execution.ssh

flow:
  name: add_user

  inputs:
    - host
    - root_password
    - user_name
    - user_password:
        default: ''
        required: false
    - group_name:
        default: ''
        required: false
    - create_home:
        default: True
        required: false
    - home_path:
        default: '/home'
        required: false

  workflow:
    - add_user:
        do:
          ssh.ssh_flow:
            - host
            - port: '22'
            - username: 'root'
            - password: ${root_password}
            - group_name_string: ${'' if group_name == '' else ' --ingroup ' + group_name}
            - create_home_string: ${'' if create_home in [True, true, 'True', 'true'] else ' --no-create-home '}
            - home_path_string: >
                ${'/home' if (home_path == '' and create_home in [True, true, 'True', 'true']) else ' --home ' +
                home_path}
            - command: >
                ${'adduser ' + user_name + ' --disabled-password --gecos \"\"' + create_home_string +
                group_name_string + home_path_string + ' && echo \"' + user_name + ':' + user_password +
                '\" | chpasswd' if user_password != '' else ''}
        publish:
          - standard_err
          - standard_out
          - return_code
          - command_return_code

  outputs:
    - standard_err
    - standard_out
    - return_code
    - command_return_code

  results:
    - SUCCESS: ${return_code == '0' and command_return_code == '0'}
    - FAILURE