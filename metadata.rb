name             'ow_python'
maintainer       'OpenWatch FPC'
maintainer_email 'contact@openwatch.net'
license          'All rights reserved'
description      'Installs/Configures ow_python'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe "ow_python", "deploys a django application at the git repo address specified in attributes"

depends "database"
depends "git_ssh_wrapper"
depends "python"
depends "application_python"