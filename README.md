## 0 Prerequisites
	the version of kubeflow is v0.1.2
	Before installing kubeflow, following are needed:
* ansible
* kubernetes
* ksonnet 
<div>
and, the installation of ksonnet can be implemeted as:
</div>
<div>
1. download binary file from github
</div>
<div>
2. unzip and cp the binary file to $PATH
</div>

---
## 1 Generate my-kubeflow directory
	run:
```console
./init.sh
```

---
## 2 Prepare images
	for some reasons, one can not get images directly.

---
## 3 Pull the images and rename
	run:
```console
./pull-go-images.sh
```

---
## 4 deploy tensorflow on kubernetes
1. cd to my-kubeflow directory
2. run:
```console
./run.sh
```

## 5 example
```bash
from tensorflow.examples.tutorials.mnist import input_data
mnist = input_data.read_data_sets("MNIST_data/", one_hot=True)

import tensorflow as tf

x = tf.placeholder(tf.float32, [None, 784])

W = tf.Variable(tf.zeros([784, 10]))
b = tf.Variable(tf.zeros([10]))

y = tf.nn.softmax(tf.matmul(x, W) + b)

y_ = tf.placeholder(tf.float32, [None, 10])
cross_entropy = tf.reduce_mean(-tf.reduce_sum(y_ * tf.log(y), reduction_indices=[1]))

train_step = tf.train.GradientDescentOptimizer(0.05).minimize(cross_entropy)

sess = tf.InteractiveSession()
tf.global_variables_initializer().run()

for _ in range(1000):
  batch_xs, batch_ys = mnist.train.next_batch(100)
  sess.run(train_step, feed_dict={x: batch_xs, y_: batch_ys})

correct_prediction = tf.equal(tf.argmax(y,1), tf.argmax(y_,1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))
print(sess.run(accuracy, feed_dict={x: mnist.test.images, y_: mnist.test.labels}))
```
Paste the example into a new Python 3 Jupyter notebook and execute the code.  
This should result in a 0.9014 accuracy result against the test data.

---
