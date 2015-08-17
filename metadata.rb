name              "proxy"
maintainer        "Martin Fenner"
maintainer_email  "martin.fenner@datacite.org"
license           "Apache 2.0"
description       "Configures proxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.2"

# opscode cookbooks
depends           "apt"
depends           "consul"

%w{ ubuntu }.each do |platform|
  supports platform
end
