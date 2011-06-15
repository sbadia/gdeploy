#!/usr/bin/env ruby
#
#

#prenom = exec("ldapsearch -x -LLL uid=#{ENV['USER']} cn |grep cn |cut -d ' ' -f 2")
#nom = exec("ldapsearch -x -LLL uid=#{ENV['USER']} cn |grep cn |cut -d ' ' -f 3")

require	'openssl'

comp = "griffon-10"


# ==== Ca Key ====
ca_key = OpenSSL::PKey::RSA.new 2048
cipher = OpenSSL::Cipher::Cipher.new 'AES-128-CBC'

open 'ca_key.pem', 'w', 0400 do |io|
  io.write key.export(cipher, 'capass')
end

ca_name = OpenSSL::X509::Name.parse '/C=FR/O=Grid5000/CN=G5K-CA'

ca_cert = OpenSSL::X509::Certificate.new
ca_cert.serial = 0
ca_cert.version = 2
ca_cert.not_before = Time.now
ca_cert.not_after = Time.now + 86400

ca_cert.public_key = ca_key.public_key
ca_cert.subject = ca_name
ca_cert.issuer = ca_name

extension_factory = OpenSSL::X509::ExtensionFactory.new
extension_factory.subject_certificate = ca_cert
extension_factory.issuer_certificate = ca_cert

extension_factory.create_extension 'subjectKeyIdentifier', 'hash'
extension_factory.create_extension 'basicConstraints', 'CA:TRUE', true
extension_factory.create_extension 'keyUsage', 'cRLSign,keyCertSign', true

ca_cert.sign ca_key, OpenSSL::Digest::SHA1.new

open 'ca_cert.pem', 'w' do |io|
  io.write ca_cert.to_pem
end


#sitename = OpenSSL::X509::Name.parse "/C=FR/O=Grid5000/OU=gLite G5K/CN=host/#{comp}.grid5000.fr"
#sicert = OpenSSL::X509::Certificate.new
#sicert.version = 2
#sicert.serial = 0
#sicert.not_before = Time.now
#sicert.not_after = Time.now + 3650
#sicert.public_key = key.public_key_ca
#sicert.subject = 'Ca Key'
#
#

