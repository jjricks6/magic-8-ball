<template>
  <div id="app">
    <Shake msg="The Magic 8-Ball"/>
  </div>
</template>

<script>
import Shake from './components/Shake.vue'

export default {
  name: 'App',
  components: {
    Shake
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
