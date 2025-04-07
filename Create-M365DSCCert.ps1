$certname = 'M365DSC'
$cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation 'Cert:\CurrentUser\My' -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
$password = ConvertTo-SecureString -String 'Changeme456!' -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath 'C:\m365dsc\M365DSC.pfx' -Password $password