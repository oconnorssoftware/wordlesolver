import React from "react";
import ReactDOM from "react-dom";
import axios from "axios";
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import Card from '@mui/material/Card';
import Paper from '@mui/material/Paper';
import { styled } from '@mui/material/styles';
import Table from '@mui/material/Table';
import TableContainer from '@mui/material/TableContainer';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableRow from '@mui/material/TableRow';
import TableHead from '@mui/material/TableHead';
import Container from '@mui/material/Container';




class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { items: [], wordblob: [], word: "", result: "" };
    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  render() {
    return (
      <Card sx={{m:6, mx:'auto', width:'80%'}} raised="true">
      <Container>
        <div>
          <center><i><h3>WORDLE Solver</h3></i></center>
        </div>
        <div>  
          <QueryList items={this.state.items} />
        </div>
        <div>  
          <TextField
            sx={{m:2}}
            name="word"
            id="word"
            error ={this.state.word.length > 5 ? true : false }
            label="Word Attempted"
            helperText="Word Entered Into Wordle"
            onChange={this.handleChange}
            value={this.state.word}
          />
        </div>
        <div>  
          <TextField
            sx={{m:2}}
            name="result"
            id="result"
            error ={this.state.result.length > 5 ? true : false }
            label="Result"
            helperText="Response G=green Y=yellow ?=Gray ex:GGY??"
            onChange={this.handleChange}
            value={this.state.result}
          />
        </div>
        <div><Button sx={{m:2}} variant="contained" onClick={this.handleSubmit}>Add #{this.state.items.length + 1}</Button></div>
        <div>
          <ResultList wordblob={this.state.wordblob} />
        </div>
      </Container>
      </Card>
    );
  }

  setStateAsync(state) {
    return new Promise((resolve) => {
      this.setState(state, resolve);
    });
  }

  handleChange(e) {
    this.setState({ [e.target.name]: e.target.value });
  }

  handleSubmit(e) {
    e.preventDefault();
    if (this.state.word.length === 0 || this.state.result.length === 0) {
      return;
    }
    if (this.state.word.length != 5 || this.state.result.length != 5){
      alert("Both the attempted word and the result box must be 5 characters")
      return;
    }
    const newItem = {
      text: this.state.word + ":" + this.state.result,
      id: Date.now(),
      result: this.state.result
    };
    this.setState(
      (state) => ({
        items: state.items.concat(newItem),
        text: ""
      }),
      () => {
        axios
          .post(process.env.API_URL+"/hello", {items: this.state.items}, {headers:{'Access-Control-Allow-Origin':'*', 'Content-Type': 'application/json', 'TEST-HEADER':'PLEASE'}})
          .then((res) => {
            this.setState({
              wordblob: res.data
            });
          });
      }
    );
  }
}


class QueryList extends React.Component {
  render() {
    return (
      <TableContainer component={Paper} sx={{m:2}}>
      <Table>
        <TableHead> Attempts
        </TableHead>
        <TableBody>
          {this.props.items.map((item) => (
            <TableRow key={item.id} selected="false">
                <TableCell>{item.text}</TableCell>
            </TableRow>))}
        </TableBody>
      </Table>
    </TableContainer>
    );
  }
}

class ResultList extends React.Component {
  render() {
    return (
      <TableContainer component={Paper} sx={{m:2}}>
      <Table>
        <TableHead>
        Word Candidates
        </TableHead>
        <TableBody>
          {this.props.wordblob.map((item, index) => (
            <TableRow key={index} selected="false">
                <TableCell>{item[0]}</TableCell>
            </TableRow>))}
        </TableBody>
      </Table>
    </TableContainer>
    );
  }
}

export default App;
