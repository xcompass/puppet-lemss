require 'spec_helper'
describe 'lemss' do
        let(:facts) do
          {
            :osfamily => 'RedHat',
            :operatingsystem => 'RedHat',
            :kernel => 'Linux'
          }
        end

        context 'with defaults for all parameters' do
          it { should contain_class('lemss') }
        end

        context 'essential parameters provided' do
          let(:params) {{:server=> "https://mylemss.server.com", :license => "xxxxxxx-xxxxxx"}}

          it do
            should contain_package('java').with_ensure('present')
            should contain_package('wget').with_ensure('present')
            should contain_service('patchagent').with_ensure('running')
          end
        end
end
