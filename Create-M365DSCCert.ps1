$certname = 'M365DSC'
$creds = get-credential -UserName "Placeholder" -Message "Enter Password for certificate creation"
$cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation 'Cert:\CurrentUser\My' -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
$password = $creds.password

Export-PfxCertificate -Cert $cert -FilePath 'C:\m365dsc\M365DSC.pfx' -Password $password