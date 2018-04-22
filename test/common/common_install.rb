describe package('docker.io') do
  it { should be_installed }
end

[
  '/etc/docker/',
  '/var/lib/docker',
].each do |consul_path|
  describe directory(consul_path) do
    it { should exist }
    it { should be_directory }
  end
end

describe file('/usr/bin/docker') do
  it { should exist }
  it { should be_file }
  it { should be_executable }
end

describe command('docker --version') do
  its('stdout') { should match /Docker version 1.6.2.*\n/ }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end
