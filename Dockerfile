FROM amazon/aws-lambda-python:3.11
ENTRYPOINT []

WORKDIR /root

# Get development tools to enable compiling
RUN yum -y update
RUN yum -y groupinstall "Development Tools"

# Get unixODBC and install it
RUN yum -y install libtool
RUN yum -y install tar gzip
RUN curl ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.11.tar.gz -O
RUN tar xvzf unixODBC-2.3.11.tar.gz
WORKDIR /root/unixODBC-2.3.11
RUN ./configure --sysconfdir=/opt/python --disable-gui --disable-drivers --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --prefix=/root/unixODBC-install
RUN make install
RUN mv /root/unixODBC-install/bin /opt/bin
RUN mv /root/unixODBC-install/lib /opt/lib
WORKDIR /root

# Install msodbcsql

RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo
RUN yum -y install e2fsprogs openssl libtool-ltdl
RUN ACCEPT_EULA=Y yum -y install msodbcsql mssql-tools --disablerepo=amzn*
RUN rm -r /opt/microsoft/msodbcsql

# Install pyodbc
# Need "unixODBC-devel" to avoid "src/pyodbc.h:56:10: fatal error: sql.h: No such file or directory" during pip install
RUN yum -y install unixODBC-devel
RUN export CFLAGS="-I/opt/microsoft/msodbcsql17/include"
RUN export LDFLAGS="-L/opt/microsoft/msodbcsql17/lib"
RUN pip install pyodbc==4.0.39 --upgrade --target /opt/python

# Add a requirements.txt file and enable this section to install other (non sql server) data-load requirements
# COPY requirements.txt /tmp/requirements.txt
# RUN pip install --requirement /tmp/requirements.txt --target /opt/python

# Create odbc.ini and odbcinst.ini
RUN echo $'[ODBC Driver 17 for SQL Server]\nDriver = ODBC Driver 17 for SQL Server\nDescription = My ODBC Driver 17 for SQL Server\nTrace = No' > /opt/python/odbc.ini
RUN so_file=$(ls /opt/microsoft/**/lib64/libmsodbcsql-*.so.* | grep msodbcsql17) && echo $'[ODBC Driver 17 for SQL Server]\nDescription = Microsoft ODBC Driver 17 for SQL Server\nDriver = '"$so_file"$'\nUsageCount = 1' > /opt/python/odbcinst.ini

# Generate the zipped file that can be uploaded as a Lambda Layer
WORKDIR /opt
RUN zip -r /layer1.zip .