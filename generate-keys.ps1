# Generate secure keys for LiteLLM
$masterKeyBytes = New-Object byte[] 32
$saltKeyBytes = New-Object byte[] 48

$rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
$rng.GetBytes($masterKeyBytes)
$rng.GetBytes($saltKeyBytes)

$masterKey = 'sk-' + [Convert]::ToBase64String($masterKeyBytes).Replace('+','-').Replace('/','_').TrimEnd('=')
$saltKey = 'sk-' + [Convert]::ToBase64String($saltKeyBytes).Replace('+','-').Replace('/','_').TrimEnd('=')

Write-Host "LITELLM_MASTER_KEY: $masterKey"
Write-Host "LITELLM_SALT_KEY: $saltKey"
