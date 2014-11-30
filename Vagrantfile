Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
     d.vagrant_vagrantfile = "#{ENV['COREOS_DIR'] || "../coreos-vagrant"}/Vagrantfile"
     d.vagrant_machine = "core-01"
  end

  config.vm.define "teamspeak" do |app|
    app.vm.provider "docker" do |d|
      d.build_dir = "./"
      d.name =  "teamspeak"
      d.env = {
        "ETCD_SERVER" => "172.17.8.101:4001",
        "SERVER_ID" => "1233"
      }
    end
  end
end
