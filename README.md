**lambda pyodbc layer for python3.11**

Use the following commands to generate pyodbc-layer.zip for python 3.11 version

          # Builds the image 
          $ docker build --platform=linux/amd64 -t mssql-lambda " specify path to the docker file "
          
          # Copies the zipped file to /tmp/pyodbc-layer.zip on the host computer
          $ docker run --platform=linux/amd64 --rm --volume /tmp:/tmp mssql-lambda cp /pyodbc.zip /tmp/
