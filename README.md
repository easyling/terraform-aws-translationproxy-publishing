# Easyling Publishing Module
## CloudFront Distributions

This module handles publishing a project in _subdomain mode_ via CloudFront distributions. Translations will be made available on the same paths as the original, under a different domain.

### Configuring languages
Languages and their corresponding domains need to be supplied to the module as a list of objects of the form
```
{
    domain = {{target domain}},
    locale = {{locale to be published}}
}
```
Both keys are required to create a viable distribution! Locale codes are of the format `en-us`.

### HTTPS
CloudFront requires certificates from AWS ACM to enable HTTPS traffic, which need to be uploaded to the _North Virginia_ region. If no certificate ARN is supplied, HTTPS _will not be available_ on the distributions!

Currently the module requires one certificate that contains all domains and exists already, but the ability to specify the ARN by-site and have Terraform create the certificates is planned.
