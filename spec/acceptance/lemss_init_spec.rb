require 'spec_helper_acceptance'

describe 'lemss class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        class {'lemss': server=>'https://mypatch.server.com', license=>'xxxxxx-xxxxxx', group=>'CTLT'
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end
