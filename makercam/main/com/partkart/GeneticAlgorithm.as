package com.partkart{
	public class GeneticAlgorithm{
		
		// seed is the first individual given to the GA
		private var seed:Individual;
		
		//private var populationsize:int;
		
		// array of individuals in our population
		private var population:Array;
		
		public function GeneticAlgorithm(adam:Individual, populationsize:int = 9):void{
			seed = adam;
			//populationsize = size;
			
			// initialize population by mutating seed individual
			population = new Array(seed);
			
			while(population.length < populationsize){
				var mutant:Individual = seed.clone();
				mutant.mutate(40);
				population.push(mutant);
			}
		}
		
		// returns a list of individuals that have no fitness yet (not yet calculated)
		public function getPending():Array{
			var pending:Array = new Array();
			for each(var individual:Individual in population){
				if(isNaN(individual.fitness)){
					pending.push(individual);
				}
			}
			
			return pending;
		}
		
		// one step in the generation. The population array is replaced by the new generation
		public function generationStep():void{
			// identify fittest in the population, this individual will be preserved in the new generation
			var fittest:Individual = population[0];
			var averagefitness:Number = 0;
			
			for each(var individual:Individual in population){
				if(individual.fitness > fittest.fitness){
					fittest = individual;
				}
				averagefitness += individual.fitness;
			}
			
			averagefitness = averagefitness/population.length;
			
			// mate up to population size - 1 members. Individuals with higher fitness are more likely to be selected for mating
			population.sort(sortByFitness);
			
			// preserve best individual in current population (elitism)
			var newpopulation:Array = new Array(population[0]);
			//var newpopulation:Array = population.slice(0,population.length-4);
			
			while(newpopulation.length < population.length){
				var male:Individual = getRandomIndividual();
				var female:Individual = male;
				while(female == male){
					female = getRandomIndividual();
				}
				// each mating produces two children
				var children:Array = male.mate(female);
				
				// slightly mutate children
				children[0].mutate(5);
				children[1].mutate(5);
					
				newpopulation = newpopulation.concat(children);
			}
			
			population = newpopulation;
		}
		
		public function sortByFitness(a:Individual, b:Individual):int{
			if(a.fitness == b.fitness || Math.abs(a.fitness-b.fitness) < 0.00001){
				if(a.secondaryfitness == b.secondaryfitness){
					return 0;
				}
				if(a.secondaryfitness > b.secondaryfitness){
					return -1;
				}
				return 1;
			}
			
			if(a.fitness > b.fitness){
				return -1;
			}
			
			return 1;
		}
		
		// this function does not return a random individual
		// the probability of selection varies by fitness - the fittest will have the greatest chance of being selected, while the least fit will have none
		// the probability distribution is linear
		private function getRandomIndividual():Individual{
			var rand:Number = Math.random();
			
			var maxprob:Number = 2/population.length;
			
			var currentlevel:Number = 0;
			
			for(var i:int=0; i<population.length; i++){
				if(currentlevel < rand && rand < currentlevel + maxprob){
					return population[i];
				}
				currentlevel += maxprob;
				maxprob -= 2/(population.length*population.length);
			}
			
			return population[0];
		}
	}
}