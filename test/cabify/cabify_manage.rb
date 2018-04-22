# The container state is checked for, at least, the first replica of the pool.

describe command('docker inspect -f {{.State}} cabify-1') do
  its('stdout') { should match /.*Running:true.*/ }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end
