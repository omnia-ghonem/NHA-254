FROM python:3.9

#RUN apt-get update && \
#    apt-get install -y python3 python3-pip

WORKDIR /app

COPY app/ /app/

RUN pip install --no-cache-dir -r /app/requirements.txt
# COPY ./html/ /usr/share/nginx/html/
# COPY ./default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

#COPY nginx.conf /etc/nginx/conf.d/default.conf
# Use Nginx as the main process
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]