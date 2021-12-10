<template>
  <v-form v-model="valid">
    <v-container>
      <v-row>
        <v-col>
          <h1>
            The Magic 8-Ball
          </h1>
        </v-col>
      </v-row>
      <v-row>
        <v-col>
          <img alt="Magic 8-Ball" src="../assets/eight-ball.png" v-bind:class="{shakey: !answer}" id="ball" height=400px width=400px>
        </v-col>
      </v-row>
      <v-row>
        <v-col>
          <transition name="slide-fade" mode="out-in">
            <div :key="answer" id="answer">
              {{ answer }}
            </div>
          </transition>
        </v-col>
      </v-row>
      <v-row>
        <v-col
          cols="10"
          justify="center"
        >
          <v-text-field
            v-model="question"
            label="Enter your question..."
            filled
            required
          ></v-text-field>
        </v-col>
        <v-col>
          <v-btn v-on:click="shake" x-large>
            Shake!
          </v-btn>
        </v-col>
      </v-row>
      
    </v-container>
  </v-form>
</template>

<script>
import axios from 'axios'

export default {
    data: () => ({
      answer: 'Ask me any question...',
      valid: true,
      question: ''
    }),
    methods: {
      shake: function() {
        this.answer = 'a'
        setTimeout(() => {
          this.answer = ''
        }, 300);
        
        setTimeout(() => {
          axios
            // CHANGE THIS ADDRESS TO YOUR OWN API
            .post("https://6awpcyoep7.execute-api.us-west-2.amazonaws.com/prd")
            .then(response => {
              console.log('🎉 API Called Successfully')
              this.answer = response.data
            })
        }, 1000);
        return true
      }
    }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h1 {
  font-size: 70px;
  color: black;
}
#answer {
  font-size: 40px;
  color: black;
}

.shakey {
  animation: shake 1s cubic-bezier(.36,.07,.19,.97) both;
  transform: translate3d(0, 0, 0);
}
@keyframes shake {
  10%, 90% {
    transform: translate3d(-2px, 0, 0);
  }
  20%, 80% {
    transform: translate3d(4px, 0, 0);
  }
  30%, 50%, 70% {
    transform: translate3d(-20px, 0, 0);
  }
  40%, 60% {
    transform: translate3d(20px, 0, 0);
  }
}

.slide-fade-enter-active {
  transition: all .3s ease;
}
.slide-fade-leave-active {
  transition: all .3s cubic-bezier(1.0, 0.5, 0.8, 1.0);
}
.slide-fade-enter, .slide-fade-leave-to
/* .slide-fade-leave-active for <2.1.8 */ {
  transform: translatey(10px);
  opacity: 0;
}
</style>
