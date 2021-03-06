require 'spec_helper_acceptance'

describe 'sssd::dbus' do

  it 'install dependencies' do
    case fact('osfamily')
    when 'RedHat'
      case fact('operatingsystemmajrelease')
      when '6'
        pp = <<-EOS
          package { 'ruby-devel':
            ensure => present,
          }
          package { 'oniguruma-devel':
            ensure => present,
          }
          package { 'oniguruma':
            ensure   => present,
            provider => 'gem',
            require  => [
              Package['ruby-devel'],
              Package['oniguruma-devel'],
            ]
          }
        EOS

        apply_manifest(pp, :catch_failures => true)
      end
    end
  end

  it 'should work with no errors' do

    pp = <<-EOS
      include ::dbus
      include ::sssd
      ::sssd::domain { 'example.com':
        id_provider               => 'ldap',
        ldap_schema               => 'rfc2307',
        ldap_uri                  => ['ldap://#{default.ip}'],
        ldap_search_base          => 'dc=example,dc=com',
        ldap_tls_reqcert          => 'never',
        ldap_id_use_start_tls     => false,
        ldap_default_bind_dn      => 'cn=Manager,dc=example,dc=com',
        ldap_default_authtok      => 'secret',
      }
      include ::sssd::dbus
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  describe package('sssd-dbus') do
    it { should be_installed }
  end

  describe file('/etc/dbus-1/system.d/org.freedesktop.sssd.infopipe.conf') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match /busconfig/ }
  end

  describe command('dbus-send --system --dest=org.freedesktop.sssd.infopipe --print-reply /org/freedesktop/sssd/infopipe org.freedesktop.sssd.infopipe.ListDomains') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /object path "\/org\/freedesktop\/sssd\/infopipe\/Domains\/example_2ecom"$/ }
  end
end
