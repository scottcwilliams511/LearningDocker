# Specify the base image we want to use.
FROM python:3.4-alpine

# Copy our application code. ADD copies the code to a new volume in the container.
ADD . /code

# Set this as our working directory so following commands will be run in this context.
WORKDIR /code

# Fetch app specific dependancies. In this case use python's 
RUN pip install -q -r requirements.txt

# Write the command for running the application. CMD tells the container which command it should
# run when it is started.
CMD ["python", "./app.py"]