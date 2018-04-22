describe package('python-pip') do
  it { should be_installed }
end

describe file('/opt/cabify/cabify.py') do
  it { should exist }
end
