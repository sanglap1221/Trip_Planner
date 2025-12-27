from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from datetime import datetime, timedelta
from api.models import Trip, ItineraryItem, Poll, PollOption, ChatMessage

User = get_user_model()


class Command(BaseCommand):
    help = 'Populates the database with sample trip data'

    def handle(self, *args, **options):
        self.stdout.write('Creating sample data...')

        # Create sample users
        demo_user, created = User.objects.get_or_create(
            username='demo',
            defaults={'email': 'demo@tripplanner.local'}
        )
        if created:
            demo_user.set_password('demo123')
            demo_user.save()
            self.stdout.write(self.style.SUCCESS(f'✓ Created user: demo (password: demo123)'))
        else:
            self.stdout.write(f'User "demo" already exists')

        traveler, created = User.objects.get_or_create(
            username='traveler',
            defaults={'email': 'traveler@tripplanner.local'}
        )
        if created:
            traveler.set_password('travel123')
            traveler.save()
            self.stdout.write(self.style.SUCCESS(f'✓ Created user: traveler (password: travel123)'))

        # Create sample trips
        trip1, created = Trip.objects.get_or_create(
            name='Tokyo Adventure 🇯🇵',
            owner=demo_user,
            defaults={
                'description': 'Exploring the vibrant streets of Tokyo - temples, tech, and amazing food!',
                'start_date': datetime.now().date() + timedelta(days=30),
                'end_date': datetime.now().date() + timedelta(days=37),
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created trip: {trip1.name}'))
            
            # Add itinerary items
            ItineraryItem.objects.create(
                trip=trip1,
                title='Visit Senso-ji Temple',
                description='Ancient Buddhist temple in Asakusa district. Arrive early to avoid crowds!',
                order=0
            )
            ItineraryItem.objects.create(
                trip=trip1,
                title='Explore Shibuya Crossing',
                description='Experience the world\'s busiest pedestrian crossing',
                order=1
            )
            ItineraryItem.objects.create(
                trip=trip1,
                title='TeamLab Borderless Museum',
                description='Immersive digital art museum - book tickets in advance',
                order=2
            )
            ItineraryItem.objects.create(
                trip=trip1,
                title='Mt. Fuji Day Trip',
                description='Take the train to Hakone for stunning views of Mt. Fuji',
                order=3
            )
            self.stdout.write('  + Added 4 itinerary items')

            # Add polls
            poll1 = Poll.objects.create(
                trip=trip1,
                question='Where should we have dinner on Day 1?',
                created_by=demo_user
            )
            PollOption.objects.create(poll=poll1, text='Sushi restaurant in Tsukiji')
            PollOption.objects.create(poll=poll1, text='Ramen shop in Shinjuku')
            PollOption.objects.create(poll=poll1, text='Izakaya in Shibuya')
            
            poll2 = Poll.objects.create(
                trip=trip1,
                question='Morning activity preference?',
                created_by=demo_user
            )
            PollOption.objects.create(poll=poll2, text='Early temple visit')
            PollOption.objects.create(poll=poll2, text='Breakfast at Tsukiji Market')
            PollOption.objects.create(poll=poll2, text='Sleep in and start at 10am')
            self.stdout.write('  + Added 2 polls')

            # Add chat messages
            ChatMessage.objects.create(
                trip=trip1,
                sender=demo_user,
                content='Super excited for this trip! 🎌'
            )
            ChatMessage.objects.create(
                trip=trip1,
                sender=demo_user,
                content='I\'ve booked the hotels in Shibuya. Anyone need the confirmation numbers?'
            )
            self.stdout.write('  + Added 2 chat messages')

        trip2, created = Trip.objects.get_or_create(
            name='Paris Weekend ✨',
            owner=demo_user,
            defaults={
                'description': 'Quick weekend getaway to the City of Light',
                'start_date': datetime.now().date() + timedelta(days=60),
                'end_date': datetime.now().date() + timedelta(days=63),
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created trip: {trip2.name}'))
            
            ItineraryItem.objects.create(
                trip=trip2,
                title='Eiffel Tower at Sunset',
                description='Book tickets online to skip the line. Sunset is around 8 PM in summer.',
                order=0
            )
            ItineraryItem.objects.create(
                trip=trip2,
                title='Louvre Museum',
                description='Morning visit - focus on Mona Lisa, Venus de Milo, and Winged Victory',
                order=1
            )
            ItineraryItem.objects.create(
                trip=trip2,
                title='Montmartre & Sacré-Cœur',
                description='Explore artist district and climb to the basilica for city views',
                order=2
            )
            self.stdout.write('  + Added 3 itinerary items')

            poll3 = Poll.objects.create(
                trip=trip2,
                question='Best day for Versailles?',
                created_by=demo_user
            )
            PollOption.objects.create(poll=poll3, text='Saturday morning')
            PollOption.objects.create(poll=poll3, text='Sunday afternoon')
            PollOption.objects.create(poll=poll3, text='Skip it, stay in Paris')
            self.stdout.write('  + Added 1 poll')

            ChatMessage.objects.create(
                trip=trip2,
                sender=demo_user,
                content='Should we rent bikes or use the metro?'
            )
            self.stdout.write('  + Added 1 chat message')

        trip3, created = Trip.objects.get_or_create(
            name='Iceland Road Trip 🏔️',
            owner=traveler,
            defaults={
                'description': 'Ring road adventure - waterfalls, glaciers, and Northern Lights',
                'start_date': datetime.now().date() + timedelta(days=90),
                'end_date': datetime.now().date() + timedelta(days=100),
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created trip: {trip3.name}'))
            
            ItineraryItem.objects.create(
                trip=trip3,
                title='Golden Circle Tour',
                description='Thingvellir, Geysir, and Gullfoss waterfall',
                order=0
            )
            ItineraryItem.objects.create(
                trip=trip3,
                title='South Coast: Seljalandsfoss & Skógafoss',
                description='Two stunning waterfalls you can walk behind!',
                order=1
            )
            ItineraryItem.objects.create(
                trip=trip3,
                title='Jökulsárlón Glacier Lagoon',
                description='Icebergs floating in the lagoon - absolutely magical',
                order=2
            )
            ItineraryItem.objects.create(
                trip=trip3,
                title='Blue Lagoon',
                description='Geothermal spa - book in advance!',
                order=3
            )
            self.stdout.write('  + Added 4 itinerary items')

            ChatMessage.objects.create(
                trip=trip3,
                sender=traveler,
                content='Don\'t forget to pack warm layers! It can be cold even in summer.'
            )
            self.stdout.write('  + Added 1 chat message')

        self.stdout.write(self.style.SUCCESS('\n✅ Sample data created successfully!'))
        self.stdout.write('\nYou can now login with:')
        self.stdout.write('  Username: demo, Password: demo123')
        self.stdout.write('  Username: traveler, Password: travel123')
