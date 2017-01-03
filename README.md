# IBM-MQ-Docker-performance

Author: [Roman Kharkovski](http://kharkovski.blogspot.com/).

This project is designed to compare performance of IBM MQ vs. RabbitMQ vs ActiveMQ. It is implemented as a set of Bash scripts to build and run Docker images for server side and client side. It runs tests using a variety of different number of queues and concurrent clients, and mesage sizes. You can read getting started instructions as well as recorded video of test runs and performance results that came out of this [project in this blog post](http://advantage.ibm.com). This project is created to automate the testing of IBM MQ (formerly WebSphere MQ) in a Docker environment. The installation, provisioning, configuration, optimizations of MQ settings and test runs are all automated using bash scripts.

This project is very similar to the MQ on "native" performance test described [in this blog post](https://advantage.ibm.com/2015/03/12/ibm-mq-vs-apache-activemq-performance-comparison-update/)

## License

See [Licence.md](Licence.md) (Apache License)