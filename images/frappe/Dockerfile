FROM frappe/erpnext:v15

USER frappe

RUN bench get-app admin-panel --branch main https://github.com/lnflash/frappe-flash-admin && \
    bench build --apps admin_panel 
