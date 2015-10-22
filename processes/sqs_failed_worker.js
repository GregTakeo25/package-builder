import SQSWorker from '../lib/SqsWorker'
import Events from '../lib/events'

class ErrorMessage {
  constructor(message) {
    const error_message = JSON.parse(message.Body)

    return {
      stage: error_message.stage,
      error: error_message.error,
      commit_hash: error_message.commit_hash,
      yum_repo: error_message.yum_repo
    }
  }
}

class Worker extends SQSWorker {

  onMessage(message, done) {

    let error_message

    try {
      error_message = new ErrorMessage(message)
    } catch(error) {
      console.log("error", error)
      done()
    }

    Events.emit('sqs:rpm:failed', error_message)

    done()
  }
}

module.exports = function() {
  new Worker({
    QueueUrl: process.env.SQS_QUEUE_FAILED,
    region: process.env.SQS_REGION
  }).start()
}

