# Easyling Publishing Module
## CloudFront Distributions

This module handles publishing a project via CloudFront distributions. Translations can be made available on the same paths as the original, under a different domain; or under different path prefixes of the same domain.

## Subdomains versus subdirectories

The module is capable of publishing in both ways. The decision on which one to use is a mostly business one. 

## Caution: care must be taken so that the same locale is never targeted in both variables!
While the module technically permits this, in such a case, the outcome is undefined for CloudFront, and is controlled by the publishing settings within Easyling.

### Subdomain mode
By supplying the `domain_to_locale` variable, the module publishes the targeted locales in _subdomain mode_. In subdomain mode, the module creates one distribution for each targeted domain-locale pair, making the translations available
 on the same path, e.g. `https://www.example.com/foo/bar/` becomes `https://jp.example.com/foo/bar`.
 
### Subdirectory mode
#### Disclaimer: due to Terraform's immutable resource handling, it _will_ overwrite the currently-existing distribution if CloudFront is already being used to serve the original site! To preserve continuity, you may need to patch your existing Terraform definitions manually.
By supplying the `prefix_to_locale` **and** the `source_domain` variable (both are required in this case), the module operates in _subdirectory mode_: one distribution is created with _n_+1 origins (for _n_ target locales and the source) and the translations become available under different path prefixes of the same domain, e.g. `https://www.example.com/foo/bar/` becomes `https://www.example.com/jp/foo/bar`.

### Configuring languages
Languages and their corresponding domains need to be supplied to the module as a list of objects of the form
```
{
    target = {{target identifier - path prefix or domain}},
    locale = {{locale to be published}}
}
```
Both keys are required to create a viable distribution! Locale codes are of the format `en-us`.

### HTTPS
CloudFront requires certificates from AWS ACM to enable HTTPS traffic, which need to be uploaded to the _North Virginia_ region. If no certificate ARN is supplied, HTTPS _will not be available_ on the distributions!

Currently the module requires one certificate that contains all domains and exists already, but the ability to specify the ARN by-site and have Terraform create the certificates is planned.
