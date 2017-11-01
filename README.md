# Install IBM Cloud Private (ICP)
* I created this to allow me to deploy ICP fast.
* These scripts comes as-is with no promise of functionality or accuracy.  Feel free to change or improve it any way you see fit.
* I always refer back to the [ICP's official documentation](https://www.ibm.com/support/knowledgecenter/SSBS6K/product_welcome_cloud_private.html) for help.
## Required file for Community Edition and Enterprise Edition
1. Carefully read and edit this file with all the necessary information
    * [install.conf](install.conf)
2. Run this on all nodes
    * [install_p1.sh](install_p1.sh)
3. Run the install on the master node (have install.conf in the same directory)
    * For Community Edition: [install_p2_ce.sh](install_p2_ce.sh) (tested) (online installation)
    * For Enterprise Edition: [install_p2_ee.sh](install_p2_ce.sh) (tested) (offline installation)
        * Make sure ibm-cloud-private-x86_64-2.1.0.tar.gz is in the same directory

## Others
* Run the uninstall on the master node.
    * [uninstall_icp_ce.sh](uninstall_ce.sh) (not tested)
    * [uninstall_icp_ee.sh](uninstall_ee.sh) (not tested)
