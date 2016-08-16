# Build as: docker build -t aws-stack .
# Run as: docker run --rm -it --net=host \
#    -v $PWD:$PWD -w $PWD \
#    -v /tmp:/tmp -v ~/.aws:/root/.aws \
#    -e AWS_DEFAULT_REGION=us-east-1 aws-stack make amis

FROM python:3.5-slim
RUN pip3 install mypy-lang==0.4 flake8==2.5.4 pyyaml boto3
RUN apt-get update \
  && apt-get install -y curl unzip make \
  && apt-get clean

COPY tools /usr/local/bin
RUN curl -sL "https://releases.hashicorp.com/terraform/0.7.2/terraform_0.7.2_linux_amd64.zip"> terraform.zip \
  && unzip terraform.zip \
  && mv terraform /usr/local/bin

RUN curl -sL "https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip" > packer.zip \
  && unzip packer.zip \
  && mv packer /usr/local/bin

ADD . /src

RUN cd /src && make install
