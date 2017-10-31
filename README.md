Odoo-enterprise docker
===================

Docker configuration for **Odoo Enterprise** or **Odoo Community**. This configuration has been tested with Odoo 10, but should work with other versions.

-------------
Usage
-------------

1.- Update the **docker_compose.yml** file with the GIT url for the **Odoo** project you want to clone (Example: https://your_git_user:your_git_password@github.com/your_git_user/enterprise.git). The community version is installed by default and on top of that, the enterprise version is added in the addons path. If the URL is missing, then only the community version will be available.

`GIT_ENTERPRISE_URL=<GIT ENTERPRISE URL>`

2.- By default, version 10 will be cloned. But you can change that in **Dockerfile**:

    `ENV ODOO_BRANCH=10.0`

3.- Once your settings are ready (and Docker installed), run `docker-compose up`. This will install Odoo and Postgres 9.5.

4.- Once the service is up, go to your browser and open http://localhost:8069 . You will see the Odoo welcome page. The master password for the DB is printed out in the terminal.