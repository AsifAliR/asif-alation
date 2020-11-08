describe aws_ec2_instances do
  its('instance_ids.count') { should cmp 2 }
end

aws_ec2_instances.instance_ids.each do |instance_id|
  describe aws_ec2_instance(instance_id) do
    it { should exist }
    it { should be_running }
  end
end

describe aws_security_group(group_name: 'asif_lb') do
  it { should allow_in(port: 80, ipv4_range: '0.0.0.0/0') }
end

describe aws_security_group(group_name: 'asif_example') do
  it { should_not allow_in(port: 80, ipv4_range: '0.0.0.0/0') }
end
