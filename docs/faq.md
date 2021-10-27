# Frequently Asked Questions

- **Q:** How to upgrade Puppet AEM Curator?<br>
  **A:** If you are upgrading the version of Puppet AEM Curator in the Puppetfile, be sure to check if Puppet AEM Resources need to be upgraded as well. To do so, check the `metadata.json` file under Puppet Aem Curator to see if the Puppet AEM Resources version if different to the one in the Puppetfile. If so, you have to also update the Puppet AEM Resources version in AEM AWS Stack Provisioner's Puppetfile.
